all:
  hosts:
%{ for name, ip in masters ~}
    ${name}:
      ansible_host: ${ip}
%{ endfor ~}
%{ for name, ip in workers ~}
    ${name}:
      ansible_host: ${ip}
%{ endfor ~}
  children:
    kube_control_plane:
      hosts:
%{ for name, ip in masters ~}
        ${name}:
%{ endfor ~}
    kube_node:
      hosts:
%{ for name, ip in masters ~}
        ${name}:
%{ endfor ~}
%{ for name, ip in workers ~}
        ${name}:
%{ endfor ~}
    etcd:
      hosts:
%{ for name, ip in masters ~}
        ${name}:
%{ endfor ~}
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}