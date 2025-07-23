terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_vpc" "default" {
  default = true
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
  name        = "strapi-sg-${random_pet.name.id}" # ✅ unique SG name
  description = "Allow Strapi and SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress = [
    {
      description      = "Allow SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "Allow Strapi (1337)"
      from_port        = 1337
      to_port          = 1337
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = "Allow all outbound"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

resource "aws_instance" "strapi" {
  ami                         = "ami-024e6efaf93d85776" # ✅ Ubuntu 22.04 for EC2 Connect in us-east-2
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.strapi_key.key_name
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOT
              #!/bin/bash
              apt update -y
              apt install -y docker.io docker-compose
              systemctl start docker
              systemctl enable docker
            EOT

  tags = {
    Name = "strapi-instance"
  }
}

output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.strapi_key.private_key_pem
  sensitive = true
}
