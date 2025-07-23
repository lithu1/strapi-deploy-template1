variable "aws_access_key" {
  description = "AWS access key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "image_tag" {
  description = "Tag for the Docker image"
  type        = string
  default     = "latest"
}
