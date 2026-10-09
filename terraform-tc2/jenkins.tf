



# Generates the key pair for the master node
resource "tls_private_key" "master_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Saves the private key locally
resource "local_file" "master_private_key" {
  # PEM - privacy enhanced mail
  content = tls_private_key.master_key.private_key_pem
  # The path.module denotes where the current file (root main.tf) lives which is under terraform-onepercent directory
  # Don't let the naming confuse you. So the pem file path will be ~/terraform-onepercent/master-private-key.pem
  filename        = "${path.module}/master-private-key.pem"
  file_permission = "0600"
}

# Uploads public key to AWS
resource "aws_key_pair" "master_public_key" {
  key_name   = "master-public-key"
  public_key = tls_private_key.master_key.public_key_openssh
}


data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}


# Creates the EC2 
resource "aws_instance" "jenkins_server" {

  ami           = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = "t3.small"

  vpc_security_group_ids = [
    aws_security_group.jenkins_sg.id
  ]

  subnet_id = aws_subnet.public_subnet_1.id

  iam_instance_profile = aws_iam_instance_profile.jenkins_instance_profile.name



  key_name = aws_key_pair.master_public_key.key_name

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }


  tags = {
    Project = "Tech-Challenge-2"
  }
}