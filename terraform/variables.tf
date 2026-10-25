variable "aws_region" {
  description = "AWS region used by the local emulator"
  type        = string
  default     = "us-east-1"
}

variable "floci_endpoint" {
  description = "Floci API endpoint used by Terraform"
  type        = string
  default     = "http://localhost:4566"
}

variable "project_name" {
  description = "Prefix for all resource names"
  type        = string
  default     = "books-api"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

variable "lambda_runtime" {
  description = "Lambda runtime (must match the Python version used to build the package)"
  type        = string
  default     = "python3.13"
}

variable "lambda_package_dir" {
  description = "Directory with the built Lambda package (created by build.ps1)"
  type        = string
  default     = "../build/package"
}
