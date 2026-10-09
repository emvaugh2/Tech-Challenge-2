########################################################################
######################## Shared IAM Data ###############################
########################################################################
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
########################################################################
######################## Jenkins IAM Section ###########################
########################################################################
# Allows the Jenkins EC2 instance to assume this IAM role.
data "aws_iam_policy_document" "jenkins_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}
# Creates the IAM role used by the Jenkins EC2 instance.
resource "aws_iam_role" "jenkins_role" {
  name               = "tc2-jenkins-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume_role_policy.json
  tags = {
    Name    = "tc2-jenkins-role"
    Project = "Tech-Challenge-2"
  }
}
# Grants Jenkins permission to authenticate to ECR, push the Flask image,
# and retrieve the EKS cluster information required to generate kubeconfig.
data "aws_iam_policy_document" "jenkins_deployment_policy" {
  statement {
    sid    = "GetECRAuthorizationToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "PushFlaskImageToECR"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [
      aws_ecr_repository.python_hcw.arn
    ]
  }
  statement {
    sid    = "DescribeEKSResources"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "eks:ListClusters"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ReadAddonIAMRoles"
    effect = "Allow"
    actions = [
      "iam:GetRole"
    ]
    resources = [
      aws_iam_role.aws_load_balancer_controller_role.arn,
      aws_iam_role.cluster_autoscaler_role.arn
    ]
  }

  statement {
    sid    = "IdentifyCaller"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }
}
# Creates the Jenkins deployment policy.
resource "aws_iam_policy" "jenkins_deployment_policy" {
  name        = "tc2-jenkins-deployment-policy"
  description = "Allows Jenkins to push images to ECR and deploy to EKS"
  policy      = data.aws_iam_policy_document.jenkins_deployment_policy.json
  tags = {
    Name    = "tc2-jenkins-deployment-policy"
    Project = "Tech-Challenge-2"
  }
}
# Attaches the deployment policy to the Jenkins role.
resource "aws_iam_role_policy_attachment" "jenkins_deployment_policy_attachment" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_deployment_policy.arn
}
# Creates the instance profile that attaches the Jenkins role to EC2.
resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "tc2-jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
  tags = {
    Name    = "tc2-jenkins-instance-profile"
    Project = "Tech-Challenge-2"
  }
}
########################################################################
######################## EKS OIDC Section ##############################
########################################################################
# Creates an IAM OIDC provider for the EKS cluster.
# This allows Kubernetes service accounts to assume dedicated IAM roles.
resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  client_id_list = [
    "sts.amazonaws.com"
  ]
  tags = {
    Name    = "tc2-eks-oidc-provider"
    Project = "Tech-Challenge-2"
  }
}
# Removes https:// from the OIDC issuer URL so it can be used as an IAM
# condition-key prefix.
locals {
  eks_oidc_issuer = replace(
    aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer,
    "https://",
    ""
  )
}
########################################################################
################## Load Balancer Controller IAM ########################
########################################################################
# Downloads the official IAM policy for AWS Load Balancer Controller v2.14.1.
data "http" "aws_load_balancer_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json"
}
# Creates the IAM policy used by the AWS Load Balancer Controller.
resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  name        = "tc2-aws-load-balancer-controller-policy"
  description = "Allows the AWS Load Balancer Controller to manage ALB resources"
  policy      = data.http.aws_load_balancer_controller_policy.response_body
  tags = {
    Name    = "tc2-aws-load-balancer-controller-policy"
    Project = "Tech-Challenge-2"
  }
}
# Allows only the aws-load-balancer-controller service account in the
# kube-system namespace to assume the controller IAM role.
data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.eks_oidc_provider.arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_issuer}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_issuer}:sub"
      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }
  }
}
# Creates the IAM role used by the AWS Load Balancer Controller pod.
resource "aws_iam_role" "aws_load_balancer_controller_role" {
  name               = "tc2-aws-load-balancer-controller-role"
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  tags = {
    Name    = "tc2-aws-load-balancer-controller-role"
    Project = "Tech-Challenge-2"
  }
}
# Attaches the controller policy to the controller role.
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_policy_attachment" {
  role       = aws_iam_role.aws_load_balancer_controller_role.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller_policy.arn
}
########################################################################
#################### Cluster Autoscaler IAM ############################
########################################################################
# Allows only the cluster-autoscaler service account in the kube-system
# namespace to assume the autoscaler IAM role.
data "aws_iam_policy_document" "cluster_autoscaler_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.eks_oidc_provider.arn
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_issuer}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_issuer}:sub"
      values = [
        "system:serviceaccount:kube-system:cluster-autoscaler"
      ]
    }
  }
}
# Defines the AWS permissions required by Cluster Autoscaler.
data "aws_iam_policy_document" "cluster_autoscaler_policy" {
  statement {
    sid    = "AllowClusterAutoscalerReadOperations"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowClusterAutoscalerWriteOperations"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"

      values = [
        "true"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/${aws_eks_cluster.eks_cluster.name}"

      values = [
        "owned"
      ]
    }
  }
}

# Creates the Cluster Autoscaler IAM policy.
resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "tc2-cluster-autoscaler-policy"
  description = "Allows Cluster Autoscaler to manage EKS worker-node capacity"
  policy      = data.aws_iam_policy_document.cluster_autoscaler_policy.json

  tags = {
    Name    = "tc2-cluster-autoscaler-policy"
    Project = "Tech-Challenge-2"
  }
}

# Creates the IAM role used by the Cluster Autoscaler pod.
resource "aws_iam_role" "cluster_autoscaler_role" {
  name = "tc2-cluster-autoscaler-role"

  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role_policy.json

  tags = {
    Name    = "tc2-cluster-autoscaler-role"
    Project = "Tech-Challenge-2"
  }
}

# Attaches the autoscaler policy to the autoscaler role.
resource "aws_iam_role_policy_attachment" "cluster_autoscaler_policy_attachment" {
  role       = aws_iam_role.cluster_autoscaler_role.name
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
}