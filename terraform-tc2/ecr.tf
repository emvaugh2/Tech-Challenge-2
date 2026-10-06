#Creates the frontend and backend repositories to store our images for our applications. 

resource "aws_ecr_repository" "frontend_repo" {
  name                 = "frontend-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "Tech-Challenge-1"
  }
}

resource "aws_ecr_repository" "backend_repo" {
  name                 = "backend-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "Tech-Challenge-1"
  }
}

# Creates the lifecyle policies  for the frontend and backend repositories. It says don't keep any images older than 14 days. 



resource "aws_ecr_lifecycle_policy" "frontend_repo_lcp" {
  repository = aws_ecr_repository.frontend_repo.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire images older than 14 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 14
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

resource "aws_ecr_lifecycle_policy" "backend_repo_lcp" {
  repository = aws_ecr_repository.backend_repo.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire images older than 14 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 14
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}