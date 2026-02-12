terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# 1) Kinesis Data Stream
# -------------------------
resource "aws_kinesis_stream" "telemax_stream" {
  name             = "${var.project_name}-stream"
  shard_count      = 1
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

# Why:
# - shard_count=1 keeps cost/complexity low for a lab
# - retention_period=24 hours gives you time to replay/test

# -------------------------
# 2) DynamoDB table
# -------------------------
resource "aws_dynamodb_table" "telemax_table" {
  name         = "${var.project_name}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }
}

# Why:
# - PAY_PER_REQUEST avoids capacity planning for labs
# - pk/sk pattern is flexible for NoSQL warehousing style storage

# -------------------------
# 3) IAM role for Lambda
# -------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# CloudWatch Logs permissions (so you can see Lambda logs)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to read from Kinesis
resource "aws_iam_role_policy" "lambda_kinesis_read" {
  name = "${var.project_name}-lambda-kinesis-read"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:ListShards",
          "kinesis:ListStreams"
        ]
        Resource = aws_kinesis_stream.telemax_stream.arn
      }
    ]
  })
}

# Allow Lambda to write into DynamoDB
resource "aws_iam_role_policy" "lambda_ddb_write" {
  name = "${var.project_name}-lambda-ddb-write"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = aws_dynamodb_table.telemax_table.arn
      }
    ]
  })
}

# Why:
# - Lambda needs permissions for logging, reading Kinesis records, and writing to DynamoDB.
# - If permissions are wrong, records won’t move and you’ll see errors in CloudWatch.

# -------------------------
# 4) Package Lambda code
# -------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "telemax_consumer" {
  function_name = "${var.project_name}-consumer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.telemax_table.name
    }
  }
}

# Why:
# - archive_file zips your lambda/ folder into lambda.zip
# - source_code_hash makes Terraform redeploy when code changes

# -------------------------
# 5) Connect Kinesis → Lambda (event source mapping)
# -------------------------
resource "aws_lambda_event_source_mapping" "kinesis_to_lambda" {
  event_source_arn  = aws_kinesis_stream.telemax_stream.arn
  function_name     = aws_lambda_function.telemax_consumer.arn
  starting_position = "LATEST"
  batch_size        = 100
  enabled           = true
}

# Why:
# - This is the “subscription” that makes Lambda auto-trigger from Kinesis
# - LATEST means “only new records from now on”
