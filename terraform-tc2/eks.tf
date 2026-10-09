########################################################################
######################### EKS Cluster Section ##########################
########################################################################



# Creates the IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "tc2-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

# Chooses the policy and attaches that policy to the IAM role for the EKS cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Creates the EKS Cluster (Control Plane) resource

resource "aws_eks_cluster" "eks_cluster" {
  name = "tc2-eks-cluster"

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.35"

  vpc_config {
    subnet_ids = [aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id]

    endpoint_public_access  = true
    endpoint_private_access = true
  }



  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = {
    Project = "Tech-Challenge-2"
  }
}




########################################################################
######################## EKS Node Group Section ########################
########################################################################


# Creates the IAM role for the EKS node group
resource "aws_iam_role" "eks_node_group_role" {
  name = "tc2-eks-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


# Creates the mandatory policies for our EKS Node Group resource
resource "aws_iam_role_policy_attachment" "EKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "EKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "EC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}



# Creates the EKS node group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "tc2-eks-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids = [aws_subnet.private_subnet_1.id,
  aws_subnet.private_subnet_2.id]
  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 4
    min_size     = 1
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.EKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.EKS_CNI_Policy,
    aws_iam_role_policy_attachment.EC2ContainerRegistryReadOnly,
  ]

  tags = {
    Project = "Tech-Challenge-2"
  }
}


resource "aws_eks_access_entry" "jenkins_box" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_iam_role.jenkins_role.arn

}

resource "aws_eks_access_policy_association" "eks_jenkins_box_policy_assoc" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.jenkins_role.arn

  access_scope {
    type = "cluster"
  }
  depends_on = [
    aws_eks_access_entry.jenkins_box
  ]

}