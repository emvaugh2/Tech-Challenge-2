pipeline {
    agent any
    environment {
        AWS_REGION              = 'us-east-1'
        AWS_DEFAULT_REGION      = 'us-east-1'
        ECR_REPOSITORY_NAME     = 'hello-cruel-world-repo'
        EKS_CLUSTER_NAME        = 'tc2-eks-cluster'
        KUBERNETES_NAMESPACE    = 'tc2'
        HELM_RELEASE_NAME       = 'hello-cruel-world'
        LOCAL_IMAGE_NAME        = 'hello-cruel-world'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh '''
                    set -eux
                    echo "Workspace: $WORKSPACE"
                    git status
                    git log -1 --oneline
                    ls -la
                '''
            }
        }
        stage('Initialize Build') {
            steps {
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    env.ECR_REPOSITORY = sh(
                        script: '''
                            aws ecr describe-repositories \
                                --repository-names "$ECR_REPOSITORY_NAME" \
                                --region "$AWS_REGION" \
                                --query 'repositories[0].repositoryUri' \
                                --output text
                        ''',
                        returnStdout: true
                    ).trim()
                    env.ECR_REGISTRY = sh(
                        script: '''
                            ECR_REPOSITORY=$(aws ecr describe-repositories \
                                --repository-names "$ECR_REPOSITORY_NAME" \
                                --region "$AWS_REGION" \
                                --query 'repositories[0].repositoryUri' \
                                --output text)
                            printf '%s' "${ECR_REPOSITORY%/*}"
                        ''',
                       returnStdout: true
                    ).trim()
                    env.FULL_IMAGE = "${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"
                    env.KUBECONFIG = "${env.WORKSPACE}/.kube/config"
                }
                sh '''
                    set -eux
                    echo "Image tag:       $IMAGE_TAG"
                    echo "ECR repository:  $ECR_REPOSITORY"
                    echo "ECR registry:    $ECR_REGISTRY"
                    echo "Full image:      $FULL_IMAGE"
                    echo "Kubeconfig:      $KUBECONFIG"
                    test -n "$IMAGE_TAG"
                    test -n "$ECR_REPOSITORY"
                    test "$ECR_REPOSITORY" != "None"
                    test -n "$ECR_REGISTRY"
                '''
            }
        }
        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eux
                    docker build \
                        -t "$LOCAL_IMAGE_NAME:$IMAGE_TAG" \
                        ./app
                    docker image inspect \
                        "$LOCAL_IMAGE_NAME:$IMAGE_TAG"
                '''
            }
        }
        stage('Authenticate to ECR') {
            steps {
                sh '''
                    set -eux
                    aws ecr get-login-password \
                        --region "$AWS_REGION" |
                    docker login \
                        --username AWS \
                        --password-stdin "$ECR_REGISTRY"
                '''
            }
        }
        stage('Push Image to ECR') {
            steps {
                sh '''
                    set -eux
                    docker tag \
                        "$LOCAL_IMAGE_NAME:$IMAGE_TAG" \
                        "$FULL_IMAGE"
                    docker push "$FULL_IMAGE"
                '''
            }
        }
        stage('Configure EKS') {
            steps {
                sh '''
                    set -eux
                    mkdir -p "$(dirname "$KUBECONFIG")"
                    aws eks update-kubeconfig \
                        --region "$AWS_REGION" \
                        --name "$EKS_CLUSTER_NAME" \
                        --kubeconfig "$KUBECONFIG"
                    kubectl config current-context
                    kubectl get nodes
                '''
            }
        }
        stage('Validate Helm Chart') {
            steps {
                sh '''
                    set -eux
                    helm lint ./helm/hello-cruel-world
                    helm template "$HELM_RELEASE_NAME" \
                        ./helm/hello-cruel-world \
                        --namespace "$KUBERNETES_NAMESPACE" \
                        --set-string image.repository="$ECR_REPOSITORY" \
                        --set-string image.tag="$IMAGE_TAG" \
                        > "$WORKSPACE/rendered-manifests.yaml"
                    grep -n "image:.*$IMAGE_TAG" \
                        "$WORKSPACE/rendered-manifests.yaml"
                    grep -n "containerPort: 5000" \
                        "$WORKSPACE/rendered-manifests.yaml"
                '''
            }
        }
        stage('Deploy with Helm') {
            steps {
                sh '''
                    set -eux
                    helm upgrade --install "$HELM_RELEASE_NAME" \
                        ./helm/hello-cruel-world \
                        --namespace "$KUBERNETES_NAMESPACE" \
                        --create-namespace \
                        --set-string image.repository="$ECR_REPOSITORY" \
                        --set-string image.tag="$IMAGE_TAG"
                    helm status "$HELM_RELEASE_NAME" \
                        --namespace "$KUBERNETES_NAMESPACE"
                '''
            }
        }
        stage('Verify Rollout') {
            steps {
                sh '''
                    set -eux
                    kubectl rollout status \
                        deployment/hello-cruel-world \
                        --namespace "$KUBERNETES_NAMESPACE" \
                        --timeout=3m
                    kubectl get deployment,pods,service,ingress,hpa \
                        --namespace "$KUBERNETES_NAMESPACE" \
                        -o wide
                    DEPLOYED_IMAGE=$(kubectl get deployment hello-cruel-world \
                        --namespace "$KUBERNETES_NAMESPACE" \
                        -o jsonpath='{.spec.template.spec.containers[0].image}')
                    echo "Expected image: $FULL_IMAGE"
                    echo "Deployed image: $DEPLOYED_IMAGE"
                    test "$DEPLOYED_IMAGE" = "$FULL_IMAGE"
                '''
            }
        }
        stage('Smoke Test') {
            steps {
                sh '''
                    set -eux
                    ALB_DNS=$(kubectl get ingress hello-cruel-world \
                        --namespace "$KUBERNETES_NAMESPACE" \
                        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                    test -n "$ALB_DNS"
                    echo "Testing application at http://$ALB_DNS/"
                    ATTEMPT=1
                    MAX_ATTEMPTS=12
                    until RESPONSE=$(curl \
                        --silent \
                        --show-error \
                        --fail \
                        --max-time 10 \
                        "http://$ALB_DNS/"); do
                        if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
                            echo "Application failed smoke test after $MAX_ATTEMPTS attempts."
                            exit 1
                        fi
                        echo "Attempt $ATTEMPT failed. Retrying in 10 seconds..."
                        ATTEMPT=$((ATTEMPT + 1))
                        sleep 10
                    done
                    echo "Application response: $RESPONSE"
                    echo "$RESPONSE" |
                        grep -F "Hello, (cruel) World!"
                '''
            }
        }
    }
    post {
        success {
            echo "Deployment completed successfully."
            echo "Deployed image: ${env.FULL_IMAGE}"
        }
        failure {
            echo "Pipeline failed. Collecting Kubernetes diagnostics."
            sh '''
                if [ -f "$KUBECONFIG" ]; then
                    kubectl get deployment,pods,service,ingress,hpa \
                        --namespace "$KUBERNETES_NAMESPACE" \
                        -o wide || true
                    kubectl get events \
                        --namespace "$KUBERNETES_NAMESPACE" \
                        --sort-by='.metadata.creationTimestamp' || true
                    kubectl describe deployment hello-cruel-world \
                        --namespace "$KUBERNETES_NAMESPACE" || true
                fi
            '''
        }
        always {
            sh '''
                if [ -n "${ECR_REGISTRY:-}" ]; then
                    docker logout "$ECR_REGISTRY" || true
                fi
                rm -f "$WORKSPACE/rendered-manifests.yaml"
            '''
            cleanWs()
        }
    }
}

