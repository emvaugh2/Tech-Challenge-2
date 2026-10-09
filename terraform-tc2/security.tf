

# Creates the security group for the master Jenkins server
resource "aws_security_group" "jenkins_sg" {
  name        = "Jenkins-Security-Group"
  description = "This is the security group for the Jenkins server"
  vpc_id      = aws_vpc.supernet.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
  }


  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }



  tags = {
    Project = "Tech-Challenge-2"
  }
}


resource "aws_vpc_security_group_ingress_rule" "eks_api_inbound" {
  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
  description       = "Allow Jenkins to access the EKS Kubernetes API."

  referenced_security_group_id = aws_security_group.jenkins_sg.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}