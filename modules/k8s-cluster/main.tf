# modules/k8s-cluster/main.tf
# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content = templatefile("${path.module}/inventory.tpl", {
    masters      = var.master_instances
    workers      = var.worker_instances
    cluster_name = var.cluster_name
  })
}

# Generate Ansible vars
resource "local_file" "ansible_vars" {
  filename = "${path.module}/group_vars/all/all.yml"
  content = templatefile("${path.module}/all.yml.tpl", {
    cluster_name = var.cluster_name
    kube_version = var.kube_version
  })
}

# Create directory structure
resource "local_file" "create_dirs" {
  filename = "${path.module}/group_vars/.keep"
  content  = ""
}

# Upload files to bastion
resource "null_resource" "upload_files" {
  triggers = {
    inventory_hash = local_file.ansible_inventory.content
    vars_hash      = local_file.ansible_vars.content
  }

  # Upload inventory file
  provisioner "file" {
    source      = local_file.ansible_inventory.filename
    destination = "/tmp/inventory.ini"

    connection {
      type        = "ssh"
      host        = var.bastion_ip
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
    }
  }

  # Upload ansible vars
  provisioner "file" {
    source      = local_file.ansible_vars.filename
    destination = "/tmp/all.yml"

    connection {
      type        = "ssh"
      host        = var.bastion_ip
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
    }
  }

  # Upload deploy script
  provisioner "file" {
    source      = "${path.module}/deploy.sh"
    destination = "/tmp/deploy.sh"

    connection {
      type        = "ssh"
      host        = var.bastion_ip
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
    }
  }

  # Upload kubeconfig script
  provisioner "file" {
    source      = "${path.module}/get-kubeconfig.sh"
    destination = "/tmp/get-kubeconfig.sh"

    connection {
      type        = "ssh"
      host        = var.bastion_ip
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
    }
  }

  depends_on = [
    local_file.ansible_inventory,
    local_file.ansible_vars
  ]
}

# Run Kubespray deployment
resource "null_resource" "run_kubespray" {
  triggers = {
    inventory_hash = local_file.ansible_inventory.content
    vars_hash      = local_file.ansible_vars.content
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/deploy.sh",
      "/tmp/deploy.sh ${var.cluster_name} ${join(" ", [for inst in var.master_instances : inst.private_ip])} ${join(" ", [for inst in var.worker_instances : inst.private_ip])}"
    ]

    connection {
      type        = "ssh"
      host        = var.bastion_ip
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
    }
  }

  depends_on = [null_resource.upload_files]
}

# Get kubeconfig from master
resource "null_resource" "get_kubeconfig" {
  triggers = {
    cluster_instance_ids = join(",", [for inst in var.master_instances : inst.id])
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/get-kubeconfig.sh",
      "/tmp/get-kubeconfig.sh ${var.master_instances[0].private_ip} ${var.kube_version}"
    ]

    connection {
      type        = "ssh"
      host        = var.bastion_ip
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
    }
  }

  depends_on = [null_resource.run_kubespray]
}

# Create local kubeconfig for external access (optional)
resource "null_resource" "create_local_kubeconfig" {
  triggers = {
    cluster_instance_ids = join(",", [for inst in var.master_instances : inst.id])
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create local kubeconfig directory
      mkdir -p ${path.module}
      
      # Download kubeconfig from bastion
      scp -i ${var.ssh_private_key_path} \
          -o StrictHostKeyChecking=no \
          ubuntu@${var.bastion_ip}:~/.kube/config \
          ${path.module}/kubeconfig
      
      # Update server to use bastion as proxy (for external access)
      sed -i 's|server:.*|server: https://${var.bastion_ip}:6443|g' ${path.module}/kubeconfig || \
      sed -i '' 's|server:.*|server: https://${var.bastion_ip}:6443|g' ${path.module}/kubeconfig
    EOT
  }

  depends_on = [null_resource.get_kubeconfig]
}
