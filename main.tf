provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# ✅ Dynamic Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ✅ Security Group (allow SSH-free Strapi access on port 1337)
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow Strapi HTTP access"

  ingress {
    description = "Allow Strapi (port 1337)"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # No SSH ingress rule needed

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ✅ EC2 Instance running Strapi Docker container
resource "aws_instance" "strapi" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  # 🔥 No key_name (SSH disabled)
  security_groups = [aws_security_group.strapi_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras enable docker
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              docker pull ${var.docker_image}
              docker rm -f strapi-app || true
              docker run -d -p 1337:1337 --name strapi-app ${var.docker_image}
              EOF

  tags = {
    Name = "strapi-server"
  }
}

# ✅ Public IP Output
output "ec2_public_ip" {
  description = "Public IP of the Strapi EC2 instance"
  value       = aws_instance.strapi.public_ip
}
