terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region     = "eu-central-1"
  shared_config_files      = ["/Users/user/.aws/config"]
  shared_credentials_files = ["/Users/user/.aws/credentials"]
  profile                  = "default"
}

# Key Pair
resource "tls_private_key" "rsa-4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "fhstp_ctf"
  public_key = tls_private_key.rsa-4096.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.rsa-4096.private_key_pem
  filename = "fhstp_ctf"
}


# EC2 Instance
resource "aws_instance" "FHSTP_CTF" {
  ami           = "ami-0e04bcbe83a83792e"
  instance_type = "t2.medium"
  key_name      = aws_key_pair.key_pair.key_name
  security_groups = ["FHSTP_CTF_sg"]
  availability_zone = "eu-central-1b"

  root_block_device {
    volume_size = 20  
    delete_on_termination = true
  }

  user_data = <<EOF
#!/bin/bash

sudo mkdir -p /home/ubuntu/
cd /home/ubuntu/

sudo apt-get update

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install -y docker-compose-plugin vim git

git clone https://github.com/CTFd/CTFd
git clone https://github.com/apt-42/apt42_ctfd_themes.git
cp -r /home/ubuntu/apt42_ctfd_themes/watchdogs/ /home/ubuntu/CTFd/CTFd/themes/

cd /home/ubuntu/CTFd

sudo docker compose up

EOF

  tags = {
    Name = "FHSTP_CTF"
  }
}


# Security Group for EC2 Instance
resource "aws_security_group" "FHSTP_CTF_sg" {
  name = "FHSTP_CTF_sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 443
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


# VPC
data "aws_vpc" "default" {
  default = true
}
