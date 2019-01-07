output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "webservice_private_ips" {
  value = "${aws_instance.webservice.*.private_ip}"
}

output "alb-dns-name" {
  value = "${aws_alb.alb.dns_name}"
}
