variable "aws_region" {}
variable "bucket_name" {}
variable "vpc_id" {}
variable "private_subnet_cidrs" {
  type = "list"
}
variable "key_name" {
}

variable "public_key_path" {
}

variable "instance_count" {
}

variable "instance_type" {
}

variable "public_subnet_id" {
}

variable "public_subnets" {
  type = "list"
}

variable "alb_listener_port" {
}

variable "alb_listener_protocol" {
}

variable "priority" {
}

variable "svc_port" {
}

variable "target_group_path" {
}

variable "target_group_port" {
}

variable "nat_gateway_id" {
}
