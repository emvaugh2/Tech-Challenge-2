# Creates the Flask Hello Cruel World repository to store our images for our application. 

resource "aws_ecr_repository" "python_hcw" {
  name                 = "hello-cruel-world-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "Tech-Challenge-2"
  }
}


# Creates the lifecyle policy for our Flask Hello (Cruel) World repository. It says don't keep any images older than 5 days. 



resource "aws_ecr_lifecycle_policy" "python_hcw_lcp" {
  repository = aws_ecr_repository.python_hcw.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire untagged images older than 5 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

