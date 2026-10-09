# Custom Jenkins image for the TC2 EKS CI/CD pipeline
FROM jenkins/jenkins:lts-jdk21
USER root
ARG DOCKER_GID=993
ARG KUBECTL_VERSION=v1.35.0



# Install Git, Docker CLI, and supporting utilities
RUN apt-get update && \
    apt-get install -y \
      ca-certificates \
      curl \
      docker.io \
      git \
      unzip \
      jq \
      groff \
      less && \
    rm -rf /var/lib/apt/lists/*



# Install AWS CLI v2
RUN curl -fsSL \
      "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
      -o /tmp/awscliv2.zip && \
    cd /tmp && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip



# Install Helm 3
RUN curl -fsSL \
      "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" \
      | bash


# Install kubectl
RUN curl -fsSL \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
      -o /usr/local/bin/kubectl && \
    chmod 0755 /usr/local/bin/kubectl


# Match the container Docker group to the host Docker socket group
# and add Jenkins to that group
RUN groupmod -g "${DOCKER_GID}" docker && \
    usermod -aG docker jenkins


# Install the required Jenkins plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli \
      --plugin-file /usr/share/jenkins/ref/plugins.txt

USER jenkins
