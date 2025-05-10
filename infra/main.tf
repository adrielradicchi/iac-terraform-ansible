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

resource "aws_launch_template" "machine" {
  image_id      = "ami-075686beab831bb7f" 
  instance_type = var.instance
  key_name      = var.key
  security_group_names = [ var.security_group ]

  user_data = filebase64("ansible.sh")

  tags = {
    Name = "${var.key} - Terraform Ansible"
  }

  target_group_arns = [ aws_lb_target_group.target_group_lb.arn ] 
}

resource "aws_key_pair" "chaveSSH" {
  key_name = var.key
  public_key = file("${var.key}.pub")
}

resource "aws_autoscaling_group" "group" {
  launch_template {
    id      = aws_launch_template.machine.id
    version = "$Latest"
  }
  name = var.name_group
  min_size     = var.min_size
  max_size     = var.max_size
  availability_zones = [ "${var.region_aws}a", "${var.region_aws}b" ]
  # desired_capacity = var.desired_capacity
  # vpc_zone_identifier = [var.subnet_id]
}

resource "aws_default_subnet" "subnet_1" {
  availability_zone = "${var.region_aws}a" 
}

resource "aws_default_subnet" "subnet_2" {
  availability_zone = "${var.region_aws}b" 
}

resource "aws_lb" "load_balancer" {
  internal = false
  subnets = [aws_default_subnet.subnet_1.id, aws_default_subnet.subnet_2.id]
}

resource "aws_lb_target_group" "target_group_lb" {
  name     = "${var.name_group}-target-group"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_default_subnet.subnet_1.vpc_id
}

resource "aws_lb_listener" "listener_lb" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 8000
  protocol          = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group_lb.arn
  }
}

resource "aws_default_vpc" "default" {
}


# output "Public_IP" {
#   value = aws_instance.app_server.public_ip
# }
#

