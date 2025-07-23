#Loadbalancer
${loadbalancer} loadbalancer

# Servers
%{ for name, ip in servers ~}
${ip} ${name}
%{ endfor ~}

# Masters
%{ for name, ip in masters ~}
${ip} ${name}
%{ endfor ~}

# Workers
%{ for name, ip in workers ~}
${ip} ${name}
%{ endfor ~}