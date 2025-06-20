# modules/k8s-cluster/inventory.tpl
[all]
%{ for idx, master in masters ~}
${cluster_name}-master-${idx + 1} ansible_host=${master.private_ip} ip=${master.private_ip} ansible_user=ubuntu
%{ endfor ~}
%{ for idx, worker in workers ~}
${cluster_name}-worker-${idx + 1} ansible_host=${worker.private_ip} ip=${worker.private_ip} ansible_user=ubuntu
%{ endfor ~}

[kube_control_plane]
%{ for idx, master in masters ~}
${cluster_name}-master-${idx + 1}
%{ endfor ~}

[etcd]
%{ for idx, master in masters ~}
${cluster_name}-master-${idx + 1}
%{ endfor ~}

[kube_node]
%{ for idx, worker in workers ~}
${cluster_name}-worker-${idx + 1}
%{ endfor ~}

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr