variable "region_aws" {
  type = string
}

variable "key" {
  type = string
}

variable "instance" {
  type = string
}

variable "security_group" {
  type = string
}

variable "name_group" {
  type = string
}

variable "name_group_tag" {
  type = string
}

variable "min_size" {
  type = number
}

variable "max_size" {
  type = number
}

variable "production" {
  type = bool
}
