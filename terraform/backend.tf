terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.0.0"
    }
  }
  backend "s3" {
    region = "us-east-1"
    bucket = "idiliocasimiro-terraformstatebucket"
    key    = "tfstate"
  }
}