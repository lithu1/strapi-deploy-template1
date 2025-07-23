variable "aws_access_key" {
  type        = string
  description = "AWS access key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Tag for Docker image"
}
