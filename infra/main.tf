terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
  region  = var.region_aws
}

resource "aws_instance" "app_server" {
  ami           = "ami-075686beab831bb7f" 
  instance_type = var.instance
  key_name      = var.key
 
  tags = {
    Name = "${var.key} - Terraform Ansible Python"
  }
}

resource "aws_key_pair" "chaveSSH" {
  key_name = var.key
  public_key = file("${var.key}.pub")
}

output "Public_IP" {
  value = aws_instance.app_server.public_ip
}
