all:
  children:
    loadbalancer:
      hosts:
        loadbalancer:
          ansible_host: ${loadbalancer}
          hostname: loadbalancer
    servers:
      hosts:
%{ for name, ip in servers ~}
        ${name}:
          ansible_host: ${ip}
          hostname: ${name}
%{ endfor ~}
    masters:
      hosts:
%{ for name, ip in masters ~}
        ${name}:
          ansible_host: ${ip}
          hostname: ${name}
%{ endfor ~}
    workers:
      hosts:
%{ for name, ip in workers ~}
        ${name}:
          ansible_host: ${ip}
          hostname: ${name}
%{ endfor ~}