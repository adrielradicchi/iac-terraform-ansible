module "aws-dev" {
  source                 = "../../infra"
  instance               = "t2.micro"
  region_aws             = "us-west-2"
  key                    = "IaC-Dev"
  security_group         = "general_access"
  min_size               = 0
  max_size               = 2
  name_group             = "Development"
  name_group_tag         = "development"
  name_autoscaling_group = "autoscaling-development"
}

# output "IP" {
#   value = module.aws-dev.Public_IP
# }
