provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_instance" "strapi" {
  ami                    = "ami-051f7e7f6c2f40dc1" # Amazon Linux 2 AMI in us-east-2
  instance_type          = "t2.micro"
  key_name               = var.key_name            # Must match an existing key pair in your AWS account
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  tags = {
    Name = "strapi-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 80:1337 lithu213/strapi-app:${var.image_tag}
            EOF
}

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow HTTP and SSH access"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
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
