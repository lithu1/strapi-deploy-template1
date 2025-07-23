provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_instance" "strapi" {
  ami                    = "ami-0453898e98046c639" # Amazon Linux 2023 AMI
  instance_type          = "t2.micro"
  key_name               = "strapi-deploy-key"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
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
