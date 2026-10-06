
# Creates the security group for the Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "Load-Balancer-Security-Group"
  description = "This is the security group for the load balancer"
  vpc_id      = aws_vpc.supernet.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }



  tags = {
    Project = "Tech-Challenge-1"
  }
}

# Creates the security group for the Frontend traffic
resource "aws_security_group" "frontend_sg" {
  name        = "Frontend-Security-Group"
  description = "This is the security group for the frontend"
  vpc_id      = aws_vpc.supernet.id

  ingress {
    security_groups = [aws_security_group.alb_sg.id]
    from_port       = 3000
    protocol        = "tcp"
    to_port         = 3000
  }


  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }



  tags = {
    Project = "Tech-Challenge-1"
  }
}

# Creates the security group for the Backend traffic
resource "aws_security_group" "backend_sg" {
  name        = "Backend-Security-Group"
  description = "This is the security group for the backend"
  vpc_id      = aws_vpc.supernet.id

  ingress {
    security_groups = [aws_security_group.frontend_sg.id]
    from_port       = 8080
    protocol        = "tcp"
    to_port         = 8080
  }

  ingress {
    security_groups = [aws_security_group.alb_sg.id]
    from_port       = 8080
    protocol        = "tcp"
    to_port         = 8080
  }


  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }



  tags = {
    Project = "Tech-Challenge-1"
  }
}


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
    Project = "Tech-Challenge-1"
  }
}


# We need to create an ECS Task Execution role because it needs to talk to ECR and Cloudwatch. 

# This IAM role allows ECS to execute all tasks such as push/pull images and interact with Fargate
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project = "Tech-Challenge-1"
  }
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"



}






# This creates the IAM role for ECS to log via CloudWatch
resource "aws_iam_role" "ecs_logging_role" {
  name = "ecs-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })


}


resource "aws_iam_policy" "ecs_logging_policy" {
  name        = "ecs-logging-policy"
  path        = "/"
  description = "Allows the ECS service to create logs for CloudWatch"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecs_logging_policy_attach" {
  role       = aws_iam_role.ecs_logging_role.name
  policy_arn = aws_iam_policy.ecs_logging_policy.arn


}

# Jenkins will push images to ECR. So it needs to execute tasks as well. It will also have to deploy the ECS. 

# The log: part denotes CLoudWatch logs. That's how AWS knows the actions pertain to CLoudWatch Logs API. 
# The Resource: "*" means any CloudWatch Logs resources. 



resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project = "Tech-Challenge-1"
  }
}
