provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# ✅ Fetch the latest Ubuntu 22.04 LTS AMI dynamically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "strapi" {
  ami                    = data.aws_ami.ubuntu.id  # ✅ Use dynamic AMI
  instance_type          = "t2.micro"
  key_name               = "strapi-deploy-key"

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install docker.io -y
              systemctl start docker
              docker pull lithu213/strapi-app:${var.image_tag}
              docker run -d -p 80:1337 lithu213/strapi-app:${var.image_tag}
              EOF

  tags = {
    Name = "strapi-server"
  }
}

output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}
