all:
  hosts:
%{ for name, ip in servers ~}
    ${name}:
      ansible_host: ${ip}
      hostname: ${name}
%{ endif ~}
%{ endfor ~}
%{ for name, ip in masters ~}
    ${name}:
      ansible_host: ${ip}
      hostname: ${name}
%{ endfor ~}
%{ for name, ip in workers ~}
    ${name}:
      ansible_host: ${ip}
      hostname: ${name}
%{ endfor ~}
  vars:
    ansible_user: ubuntu