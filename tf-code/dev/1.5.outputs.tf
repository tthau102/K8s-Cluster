# dev/1.5.outputs.tf


output "lb_bastion-host_public_ip" {
  value = module.loadbalancer.public_ip
}
