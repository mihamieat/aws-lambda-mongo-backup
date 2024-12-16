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

resource "aws_iam_role" "lambda_role" {
  name               = "MN_DB_backup_Lambda_Function_Role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing AWS Lambda role"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   },
   {
     "Action": [
       "s3:PutObject"
     ],
     "Resource": "arn:aws:s3:::mn-mongo-backup/*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_lambda_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/package/python"
  output_path = "${path.module}/db-backup.zip"
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "${path.module}/db-backup.zip"
  function_name = "db_backup"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_lambda_role]
  environment {
    variables = {
      S3_REGION         = "eu-west-3"
      S3_BUCKET         = "mn-mongo-backup"
      CONNECTION_STRING = "mongodb+srv://autom_arch:wP8RgsebYtGnYXC3@mn0.4x7e4.mongodb.net/"
    }
  }
  timeout = 30
}
