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
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
  key_name   = "strapi-new-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "strapi" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI in us-east-2
  instance_type = "t2.micro"
  key_name      = aws_key_pair.strapi_key.key_name
  security_groups = [aws_security_group.strapi_sg.name]
  associate_public_ip_address = true
  tags = {
    Name = "strapi-server"
  }

  user_data = <<-EOT
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
              EOT
}

output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}
