variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "ap-northeast-1"
}

variable "key_name" {
  description = "key pair name to ssh connection instance"
}

variable "key_path" {
  description = "key path to ssh connection instance"
}

variable "vpc_id" {
  description = "vpc id"
}
