# /dev/7.1.dynamic-tf-ansible.tf



locals {
  hosts_entries = templatefile("${path.module}/templates/hosts.tpl", {
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

resource "local_file" "kubespray_hosts" {
  filename = "./kubespray/hosts.yaml"
  content = templatefile("${path.module}/templates/kubespray-hosts.tpl", {
    masters = {
      for i, v in module.k8s_masters : "master0${i + 1}" => v.private_ip
    }
    workers = {
      for i, v in module.k8s_workers : "worker0${i + 1}" => v.private_ip
    }
    cicd_public_ip = module.servers["cicd"].public_ip
  })
}


resource "null_resource" "cicd_ansible" {
  depends_on = [module.vpc, module.servers, local_file.ansible_inventory]

  triggers = {
    "server_id" = module.servers["cicd"].id
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${module.servers["cicd"].public_ip},' --private-key ${local_sensitive_file.key.filename} -u ubuntu -e 'hosts_entries=${base64encode(local.hosts_entries)}' playbooks/init-cicd.yml"
  }
}


resource "null_resource" "internal_servers_setup" {
  depends_on = [null_resource.cicd_ansible]

  triggers = {
    inventory_hash = local_file.ansible_inventory.content_base64sha256
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.this.private_key_openssh
    host        = module.servers["cicd"].public_ip
  }

  provisioner "remote-exec" {
    inline = ["mkdir playbooks"]
  }

  provisioner "file" {
    source      = "./playbooks/init-instance.yml"
    destination = "/home/ubuntu/playbooks/init-instance.yml"
  }

  provisioner "file" {
    source      = "./playbooks/ansible_inventory.yml"
    destination = "/home/ubuntu/inventory.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ubuntu/inventory.yml -u ubuntu -e 'hosts_entries=${base64encode(local.hosts_entries)}' /home/ubuntu/playbooks/init-instance.yml"
    ]
  }
}
