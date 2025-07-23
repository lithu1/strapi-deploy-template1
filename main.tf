terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-${random_pet.name.id}"
  description = "Allow Strapi and SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  ingress {
    description      = "Allow Strapi"
    from_port        = 1337
    to_port          = 1337
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  egress {
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
}

resource "aws_instance" "strapi" {
  ami                         = "ami-00f9f8703f9f10b8e" # ✅ Valid Amazon Linux 2 AMI for us-east-2
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              curl -sL https://rpm.nodesource.com/setup_16.x | bash -
              yum install -y nodejs git docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              docker run -d -p 1337:1337 lithu213/strapi-app:latest
              EOF

  tags = {
    Name = "strapi-instance-${random_pet.name.id}"
  }
}

output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}
