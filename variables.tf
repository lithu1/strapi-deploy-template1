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
  description = "Docker image tag to use"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name to allow SSH access (optional if using EC2 Connect)"
}
