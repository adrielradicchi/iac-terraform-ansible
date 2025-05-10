module "aws-dev" {
  source = "../../infra"
  instance = "t2.micro"
  region_aws = "us-west-2"
  key = "IaC-Dev"
  security_group = "general_access"
}

output "IP" {
  value = module.aws-dev.Public_IP
}
