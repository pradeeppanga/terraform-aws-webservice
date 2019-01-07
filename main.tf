provider "aws" {
    region = "${var.aws_region}"
    
}

# Deploy Storage Resource
module "storage" {
    source = "./storage"
    bucket_name = "${var.bucket_name}"
}

# Deploy networking 
module "networking" {
    source = "./networking"
    vpc_id = "${var.vpc_id}"
    private_subnet_cidrs = "${var.private_subnet_cidrs}"
    nat_gateway_id = "${var.nat_gateway_id}"
}

# Deploy compute resources
module "compute" {
    source = "./compute"
    key_name = "${var.key_name}"
    public_key_path = "${var.public_key_path}"
    instance_count = "${var.instance_count}"
    instance_type = "${var.instance_type}"
    subnets = "${module.networking.private_subnets}"
    vpc_id = "${var.vpc_id}"
    public_subnet_id = "${var.public_subnet_id}"
    public_subnets = "${var.public_subnets}"
    alb_listener_port = "${var.alb_listener_port}"
    alb_listener_protocol = "${var.alb_listener_protocol}"
    priority = "${var.priority}"
    svc_port = "${var.svc_port}"
    target_group_path = "${var.target_group_path}"
    target_group_port = "${var.target_group_port}"
}
    
