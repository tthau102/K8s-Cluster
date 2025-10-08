# dev/1.5.outputs.tf


output "lb_bastion-host_public_ip" {
  value = {
    for k, v in module.loadbalancer : k => [
      v.public_ip,
      v.private_ip
    ]
  }
}

output "servers-host_public_ip" {
  value = {
    for k, v in module.servers : k => v.private_ip
  }
}

output "masters-host_public_ip" {
  value = {
    for k, v in module.k8s_masters : k => v.private_ip
  }
}

output "workers-host_public_ip" {
  value = {
    for k, v in module.k8s_workers : k => v.private_ip
  }
}
