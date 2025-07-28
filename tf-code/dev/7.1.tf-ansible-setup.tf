# /dev/7.1.dynamic-tf-ansible.tf



locals {
  hosts_entries = templatefile("${path.module}/templates/hosts.tpl", {
    loadbalancer = module.loadbalancer.private_ip
    servers = {
      for k, v in module.servers : k => v.private_ip
    }
    masters = {
      for i, v in module.k8s_masters : "master0${i + 1}" => v.private_ip
    }
    workers = {
      for i, v in module.k8s_workers : "worker0${i + 1}" => v.private_ip
    }
  })
}

resource "local_file" "ansible_inventory" {
  filename = "./playbooks/ansible_inventory.yml"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    loadbalancer = module.loadbalancer.private_ip
    servers = {
      for k, v in module.servers : k => v.private_ip
    }
    masters = {
      for i, v in module.k8s_masters : "master0${i + 1}" => v.private_ip
    }
    workers = {
      for i, v in module.k8s_workers : "worker0${i + 1}" => v.private_ip
    }
  })
}


resource "null_resource" "lb_ansible" {
  depends_on = [module.vpc, module.servers, module.k8s_masters, module.k8s_workers, local_file.ansible_inventory]

  triggers = {
    "server_id" = module.loadbalancer.id
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.loadbalancer.public_ip},' --private-key ${local_sensitive_file.key.filename} -u ubuntu -e 'hosts_entries=${base64encode(local.hosts_entries)}' playbooks/init-lb.yml"
  }
}


resource "null_resource" "internal_servers_setup" {
  depends_on = [null_resource.lb_ansible]

  triggers = {
    inventory_hash = local_file.ansible_inventory.content_base64sha256
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.this.private_key_openssh
    host        = module.loadbalancer.public_ip
  }

  provisioner "remote-exec" {
    inline = ["mkdir playbooks"]
  }

  provisioner "file" {
    source      = "./playbooks/init-config.yml"
    destination = "/home/ubuntu/ansible/playbooks/init-config.yml"
  }

  provisioner "file" {
    source      = "./playbooks/ansible_inventory.yml"
    destination = "/home/ubuntu/ansible/inventory.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ubuntu/ansible/inventory.yml -u ubuntu -e 'hosts_entries=${base64encode(local.hosts_entries)}' /home/ubuntu/playbooks/init-config.yml"
    ]
  }
}
