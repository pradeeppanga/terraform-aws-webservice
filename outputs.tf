output "bastion_public_ip" {
  value = "${module.compute.bastion_public_ip}"
}

output "webservice_private_ips" {
  value = "${module.compute.webservice_private_ips}"
}

output "alb-dns-name" {
  value = "${module.compute.alb-dns-name}"
}
