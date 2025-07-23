provider "aws" {
  region = "us-east-2"
}

resource "tls_private_key" "strapi_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_pet" "name" {}

resource "aws_key_pair" "strapi_key" {
  key_name   = "strapi-deploy-key-${random_pet.name.id}"
  public_key = tls_private_key.strapi_key.public_key_openssh
}

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-${random_pet.name.id}" # ✅ Ensure unique name
  description = "Allow HTTP, HTTPS, and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
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

resource "aws_instance" "strapi" {
  ami                         = "ami-0e001c9271cf7f3b9" # Ubuntu 22.04 LTS (us-east-2)
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.strapi_key.key_name
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y docker.io docker-compose
              systemctl start docker
              systemctl enable docker
              EOF

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
