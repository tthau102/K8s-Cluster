[all]
%{ for name, ip in masters ~}
${name} ansible_host=${ip} ip=${ip} etcd_member_name=${name}
%{ endfor ~}
%{ for name, ip in workers ~}
${name} ansible_host=${ip} ip=${ip}
%{ endfor ~}

[bastion]
cicd ansible_host=${cicd_public_ip} ansible_user=ubuntu

[kube_control_plane]
%{ for name, ip in masters ~}
${name}
%{ endfor ~}

[etcd]
%{ for name, ip in masters ~}
${name}
%{ endfor ~}

[kube_node]
%{ for name, ip in masters ~}
${name}
%{ endfor ~}
%{ for name, ip in workers ~}
${name}
%{ endfor ~}

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr