provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "strapi_sg" {
  name_prefix = "strapi-sg-"
  description = "Allow inbound traffic for Strapi"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP for Strapi"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "strapi_key" {
  key_name   = "strapi-deploy-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEy7mRA4VsQ57ukPnu3ixDyTddcG2SV9t6gWuUaIlG2MtTxxkmzoX4CTZP+ucrz/T0R/AzMhz4/eDbpJOddrrlasUpbkUik2RyqkHkcOhmRha4K4+fRq+pYYCI+I5iaqU/DlvzNxmU3gqmUmsRvACXbzLJL2QBUjx1/7U/BUUvze8JWtEEsvOrULxke5b/U2r/cxAf+SvMgls49du7ac5zz+v2FTYyhjfOirpmok/vweBj8ehujRnEpizcnPsGkGa2V7TQRGnfWiIbwAI583doVFpDr84SfmMFH46AqDuXiRd0qnPLFCcc/cHXY1z5QSuwMzXhuKb61tqe4OXovM+o1IJ2/3GdrVjlTBX7hYBOspAVPKbK3RlGL9Z2+jhDKGlVfspg2IDsrndxLs5jsymYI/uHRWKwXvtyeZkFm98/BrJ7C9Lk0EKZAJFyYTRhgrp75PogqT601f5W8J3QY61VXVp3pc8+jO7G+2Mfbc41DGpL7qXQ0mCYd/r/qE4XQiTtF+cxIrj0fOk6YnnoqQhbnu9F9/JlDSHl2DVGoBeOaGqNL9/n2I2BV8CqvgclGT+AbxEuzn/ceA6xZrcjHHAFxAE40CriEwRSqaxvvQsg0VidxWkgNxd6ODjGRFVQ81in2A3IYGBUh+8ZEEdSweEe9Frk3xipSo2UuBBuQ3wKjw== root@DESKTOP-JQV1A3N"
}

resource "aws_instance" "strapi" {
  ami                    = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (HVM), SSD Volume Type - us-east-2
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.strapi_key.key_name
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "strapi-server"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras enable docker
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user

              docker pull lithu213/strapi-app:latest
              docker rm -f strapi-app || true
              docker run -d -p 1337:1337 --name strapi-app lithu213/strapi-app:latest
              EOF
}

output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}
