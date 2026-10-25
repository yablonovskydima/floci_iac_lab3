output "api_id" {
  description = "API Gateway REST API id"
  value       = aws_api_gateway_rest_api.api.id
}

output "api_url" {
  description = "Invoke URL of GET /books (Floci path form)"
  value       = "${var.floci_endpoint}/restapis/${aws_api_gateway_rest_api.api.id}/${aws_api_gateway_stage.api.stage_name}/_user_request_/books"
}

output "api_url_vhost" {
  description = "Invoke URL of GET /books (Floci execute-api host form)"
  value       = "http://${aws_api_gateway_rest_api.api.id}.execute-api.localhost.floci.io:4566/${aws_api_gateway_stage.api.stage_name}/books"
}

output "lambda_function_name" {
  value = aws_lambda_function.api.function_name
}

output "data_bucket" {
  value = aws_s3_bucket.data.bucket
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}
