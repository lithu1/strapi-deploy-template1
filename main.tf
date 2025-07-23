provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# 1. Generate SSH key pair
resource "tls_private_key" "strapi_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Upload public key to AWS
resource "aws_key_pair" "strapi_key_pair" {
  key_name   = "strapi-key-${random_id.id.hex}"
  public_key = tls_private_key.strapi_key.public_key_openssh
}

# 3. Unique ID to prevent name clashes
resource "random_id" "id" {
  byte_length = 4
}

# 4. Launch EC2 instance with generated key
resource "aws_instance" "strapi" {
  ami                         = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.strapi_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              docker run -d -p 1337:1337 lithu213/strapi-app:${var.image_tag}
              EOF

  tags = {
    Name = "StrapiInstance"
  }
}

# 5. Security group for SSH and Strapi
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow ports for Strapi and SSH"
  vpc_id      = data.aws_vpc.default.id

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

# 6. Reference default VPC
data "aws_vpc" "default" {
  default = true
}

# 7. Output private key so you can SSH
output "private_key_pem" {
  value     = tls_private_key.strapi_key.private_key_pem
  sensitive = true
}

output "instance_public_ip" {
  value = aws_instance.strapi.public_ip
}
