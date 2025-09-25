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
  tags = {
    Name = "${var.key} - Terraform Ansible"
  }
  security_group_names = [var.security_group]
  # user_data            = var.production ? filebase64("../env/Prod/ansible.sh") : ""
  user_data = var.production ? filebase64("ansible.sh") : ""
}

resource "aws_key_pair" "chaveSSH" {
  key_name   = var.key
  public_key = file("${var.key}.pub")
}

resource "aws_autoscaling_group" "group" {
  availability_zones = ["${var.region_aws}a", "${var.region_aws}b"]
  name               = var.name_group
  min_size           = var.min_size
  max_size           = var.max_size
  target_group_arns  = var.production ? [aws_lb_target_group.target_group_lb[0].arn] : []
  launch_template {
    id      = aws_launch_template.machine.id
    version = "$Latest"
  }
}

resource "aws_default_subnet" "subnet_1" {
  availability_zone = "${var.region_aws}a"
}

resource "aws_default_subnet" "subnet_2" {
  availability_zone = "${var.region_aws}b"
}

resource "aws_lb" "load_balancer" {
  internal = false
  subnets  = [aws_default_subnet.subnet_1.id, aws_default_subnet.subnet_2.id]
  count    = var.production ? 1 : 0
}

resource "aws_default_vpc" "vpc_default" {
}

resource "aws_lb_target_group" "target_group_lb" {
  name     = "${var.name_group_tag}-target-group"
  port     = "8000"
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.vpc_default.id
  health_check {
    protocol            = "HTTP"
    port                = "8000"
    timeout             = 5
    path                = "/clientes"
    interval            = 30
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  count = var.production ? 1 : 0
}

resource "aws_lb_listener" "listener_lb" {
  load_balancer_arn = aws_lb.load_balancer[0].arn
  port              = "8000"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_lb[0].arn
  }
  count = var.production ? 1 : 0
}

resource "aws_autoscaling_policy" "scale-production" {
  name                   = "${var.name_group_tag}-scale-terraform"
  autoscaling_group_name = var.name_group
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
  count = var.production ? 1 : 0
}

# output "Public_IP" {
#   value = aws_instance.app_server.public_ip
# }
#
