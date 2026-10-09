terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source = "hashicorp/local"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
