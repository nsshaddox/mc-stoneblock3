terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "Personal"
  region  = "us-west-1"
}

resource "aws_security_group" "minecraft" {
  ingress {
    description = "SSH."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["73.2.42.93/32"]
  }
  ingress {
    description = "Receive everywhere."
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Send everywhere."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Minecraft"
  }
}

resource "aws_key_pair" "home" {
  key_name   = "Home"
  public_key = "~/.ssh/id_ed25519.pub"
}

resource "aws_instance" "minecraft" {
  ami                         = "ami-0fb83b36371e7dab5" # AMI for Amazon Linux 2
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.home.key_name
  user_data                   = <<-EOF
    #!/bin/bash
    sudo yum -y update
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo yum install -y java-21-amazon-corretto-devel.x86_64
    wget -O server.jar https://piston-data.mojang.com/v1/objects/450698d1863ab5180c25d7c804ef0fe6369dd1ba/server.jar
    chmod +x server.jar
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    sed -i 's/eula=false/eula=true/' eula.txt
    java -Xmx1024M -Xms1024M -jar server.jar nogui
    EOF
  tags = {
    Name = "Minecraft"
  }
}

output "instance_ip_addr" {
  value = aws_instance.minecraft.public_ip
}

# sudo curl -JLO "https://api.modpacks.ch/public/modpack/100/12145/server/linux"