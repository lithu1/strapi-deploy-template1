provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

resource "tls_private_key" "strapi_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "strapi_key" {
  key_name   = "strapi-deploy-key-${random_pet.name.id}"
  public_key = tls_private_key.strapi_key.public_key_openssh
}

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow HTTP, HTTPS, and SSH"
  ingress = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 1337
      to_port     = 1337
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

resource "aws_instance" "strapi" {
  ami                    = "ami-053b0d53c279acc90" # ✅ Ubuntu 22.04 LTS for us-east-2
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.strapi_key.key_name
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "strapi-instance"
  }

  user_data = <<-EOT
              #!/bin/bash
              apt update -y
              apt install -y docker.io docker-compose
              systemctl start docker
              systemctl enable docker
            EOT
}

output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.strapi_key.private_key_pem
  sensitive = true
}
