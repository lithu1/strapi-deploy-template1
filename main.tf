provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_instance" "strapi" {
  ami                    = "ami-0cf10cdf9fcd62d37"  # ✅ Valid Ubuntu 22.04 LTS AMI for us-east-2
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
