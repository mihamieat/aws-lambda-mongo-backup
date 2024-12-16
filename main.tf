terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3" # Change this to your desired AWS region
}

resource "aws_s3_bucket" "mn_mongo_backup" {
  bucket = "mn-mongo-backup"

  tags = {
    Name        = "mn-mongo-backup"
    Environment = "Production"
  }
}
