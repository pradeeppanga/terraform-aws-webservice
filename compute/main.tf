data "aws_ami" "server_ami" {
    most_recent = true
    
    filter {
        name = "owner-alias"
        values = ["amazon"]
    }
    
    filter {
        name = "name"
        values = ["amzn-ami-hvm*-x86_64-gp2"]
    }
}

resource "aws_key_pair" "auth" {
    key_name = "${var.key_name}"
    public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "webservice" {
    count = "${var.instance_count}"
    instance_type = "${var.instance_type}"
    ami = "${data.aws_ami.server_ami.id}"

    tags {
        Name = "tf_server-${count.index +1}"
    }

    key_name = "${aws_key_pair.auth.id}"
    vpc_security_group_ids = ["${aws_security_group.web_sg.id}"]
    subnet_id = "${element(var.subnets, count.index)}"
    iam_instance_profile = "${aws_iam_instance_profile.web_instance_profile.name}"
    user_data = "${file("${path.module}/userdata.tpl")}"
}

resource "aws_instance" "bastion" {
    count = 1
    instance_type = "t2.micro"
    ami = "${data.aws_ami.server_ami.id}"

    tags {
        Name = "Bastion Host"
    }
    
    key_name = "${aws_key_pair.auth.id}"
    vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]
    subnet_id = "${var.public_subnet_id}"
}

resource "aws_security_group" "bastion_sg" {
    name = "bastion_sg"
    description = "Used for public access to Bastion host"
    vpc_id = "${var.vpc_id}"
    
    # SSH

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    }

     egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "alb_sg" {
    name = "alb_sg"
    description = "Used for access to ALB"
    vpc_id = "${var.vpc_id}"

    ingress {
        from_port = 8090
        to_port = 8090
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

     egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "web_sg" {
    name = "web_sg"
    description = "Used for access to instances in private subnets"
    vpc_id = "${var.vpc_id}"
    

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = ["${aws_security_group.bastion_sg.id}"]       
    }

    ingress {
        from_port = 8090
        to_port = 8090
        protocol = "tcp"
        security_groups = ["${aws_security_group.alb_sg.id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    
    }
}

resource "aws_iam_role" "ec2_s3_access_role" {
    name = "s3-role"
    assume_role_policy = "${file("${path.module}/assumerolepolicy.json")}"
}

resource "aws_iam_policy" "policy" {
    name        = "s3-policy"
    description = "S3 access policy"
    policy      = "${file("${path.module}/policys3bucket.json")}"
}

resource "aws_iam_policy_attachment" "policy-attach" {
    name       = "s3-policy-attachment"
    roles     = ["${aws_iam_role.ec2_s3_access_role.name}"]
    policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_instance_profile" "web_instance_profile" {
    name  = "web_instance_profile"
    role = "${aws_iam_role.ec2_s3_access_role.name}"
}

resource "aws_alb" "alb" {
    name            = "my-webservice-endpoint"
    subnets         = ["${var.public_subnets}"]
    security_groups = ["${aws_security_group.alb_sg.id}"]
    internal        = false
    tags {
      Name    = "my-webservice-endpoint"
    }
}

resource "aws_alb_listener" "alb_listener" {
    load_balancer_arn = "${aws_alb.alb.arn}"
    port              = "${var.alb_listener_port}"
    protocol          = "${var.alb_listener_protocol}"

    default_action {
        target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
        type             = "forward"
  }
}

resource "aws_alb_listener_rule" "listener_rule" {
  depends_on   = ["aws_alb_target_group.alb_target_group"]
  listener_arn = "${aws_alb_listener.alb_listener.arn}"
  priority     = "100"
  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.alb_target_group.id}"
  }
  condition {
    field  = "path-pattern"
    values = ["/"]
  }
}

resource "aws_alb_target_group" "alb_target_group" {
  name     = "my-webservice-tg"
  port     = "${var.svc_port}"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
  tags {
    name = "my-webservice-tg"
  }
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = true
  }
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "${var.target_group_path}"
    port                = "${var.target_group_port}"
  }
}

resource "aws_alb_target_group_attachment" "svc_physical_external" {
  count = 2 
  target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
  target_id        = "${element(aws_instance.webservice.*.id, count.index)}"
  port             = 8090
}
