variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Docker image tag (unused but passed via CLI)"
  type        = string
  default     = "latest"
}
