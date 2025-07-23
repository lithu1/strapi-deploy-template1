provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow inbound traffic for Strapi"

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

resource "aws_instance" "strapi" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (HVM), SSD Volume Type - us-east-2
  instance_type = "t2.micro"
  security_groups = [aws_security_group.strapi_sg.name]
  key_name      = "strapi-deploy-key"  # Optional if you want SSH access; remove if unused

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

  tags = {
    Name = "strapi-server"
  }
}

output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}
