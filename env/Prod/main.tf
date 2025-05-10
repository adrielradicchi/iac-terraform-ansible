module "aws-prod" {
  source = "../../infra"
  instance = "t2.micro"
  region_aws = "us-west-2"
  key = "IaC-Prod"
  security_group = "production_general_access"
}


output "IP" {
  value = module.aws-prod.Public_IP
}
