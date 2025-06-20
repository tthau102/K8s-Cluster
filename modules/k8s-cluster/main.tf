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

# Run Kubespray
resource "null_resource" "run_kubespray" {
  triggers = {
    inventory_hash = local_file.ansible_inventory.content
    vars_hash      = local_file.ansible_vars.content
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}
      
      # Clone kubespray if not exists
      if [ ! -d "kubespray" ]; then
        git clone https://github.com/kubernetes-sigs/kubespray.git
        cd kubespray
        git checkout v2.28.0
        cd ..
      fi
      
      # Create inventory directory
      mkdir -p kubespray/inventory/${var.cluster_name}/group_vars/all
      
      # Copy inventory and vars
      cp inventory.ini kubespray/inventory/${var.cluster_name}/
      cp group_vars/all/all.yml kubespray/inventory/${var.cluster_name}/group_vars/all/
      
      # Copy sample configs (k8s-cluster vars)
      cp -r kubespray/inventory/sample/group_vars/k8s_cluster kubespray/inventory/${var.cluster_name}/group_vars/ || true
      
      # Wait for instances to be ready
      sleep 60
      
      # Run kubespray via Docker
      docker run --rm \
        --mount type=bind,source="$(pwd)/kubespray",target=/kubespray \
        --mount type=bind,source="${var.ssh_private_key_path}",target=/root/.ssh/id_rsa,readonly \
        quay.io/kubespray/kubespray:v2.28.0 \
        ansible-playbook -i inventory/${var.cluster_name}/inventory.ini \
        --become --become-user=root cluster.yml
    EOT

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }

  depends_on = [
    local_file.ansible_inventory,
    local_file.ansible_vars
  ]
}

# Copy kubeconfig from master
resource "null_resource" "get_kubeconfig" {
  triggers = {
    cluster_instance_ids = join(",", [for inst in var.master_instances : inst.id])
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}
      scp -i ${var.ssh_private_key_path} \
          -o StrictHostKeyChecking=no \
          -o ProxyCommand="ssh -i ${var.ssh_private_key_path} -W %h:%p ubuntu@${var.bastion_ip}" \
          ubuntu@${var.master_instances[0].private_ip}:/home/ubuntu/.kube/config \
          ${path.module}/kubeconfig
      
      # Update server endpoint to use bastion
      sed -i 's|server:.*|server: https://${var.bastion_ip}:6443|g' ${path.module}/kubeconfig
    EOT
  }

  depends_on = [null_resource.run_kubespray]
}

