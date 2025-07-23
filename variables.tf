variable "aws_region" {
  default = "us-east-2" # or your preferred region
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "public_key_path" {
  description = "Path to your local public SSH key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "docker_image" {
  description = "Docker image to deploy (e.g. lithu213/strapi-app:latest)"
  type        = string
}
