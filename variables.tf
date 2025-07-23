variable "aws_region" {
  default = "us-east-2"
}

variable "aws_access_key" {
  description = "Your AWS access key"
}

variable "aws_secret_key" {
  description = "Your AWS secret key"
}

variable "docker_image" {
  description = "lithu213/strapi-app:latest" 
  type        = string
}
