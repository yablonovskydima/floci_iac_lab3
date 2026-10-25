locals {
  books_key  = "books.json"
  lambda_key = "lambda/${var.project_name}.zip"
}

resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-data"
}

resource "aws_s3_object" "books" {
  bucket       = aws_s3_bucket.data.id
  key          = local.books_key
  source       = "${path.module}/data/books.json"
  content_type = "application/json"
  etag         = filemd5("${path.module}/data/books.json")
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.project_name}-artifacts"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.lambda_package_dir
  output_path = "${path.module}/../build/${var.project_name}.zip"
}

resource "aws_s3_object" "lambda" {
  bucket = aws_s3_bucket.artifacts.id
  key    = local.lambda_key
  source = data.archive_file.lambda.output_path
  etag   = data.archive_file.lambda.output_md5
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_s3_read" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.data.arn}/*"]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_s3_read" {
  name   = "${var.project_name}-s3-read"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_s3_read.json
}

resource "aws_lambda_function" "api" {
  function_name    = var.project_name
  role             = aws_iam_role.lambda.arn
  runtime          = var.lambda_runtime
  handler          = "app.main.handler"
  s3_bucket        = aws_s3_object.lambda.bucket
  s3_key           = aws_s3_object.lambda.key
  source_code_hash = data.archive_file.lambda.output_base64sha256
  memory_size      = 256
  timeout          = 15

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data.bucket
      BOOKS_KEY   = aws_s3_object.books.key
    }
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name        = var.project_name
  description = "Minimal books API (API Gateway + Lambda + S3)"
}

resource "aws_api_gateway_resource" "books" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "books"
}

resource "aws_api_gateway_method" "get_books" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.books.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_books" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.books.id
  http_method             = aws_api_gateway_method.get_books.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api.invoke_arn
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.books.id,
      aws_api_gateway_method.get_books.id,
      aws_api_gateway_integration.get_books.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name    = var.stage_name
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
