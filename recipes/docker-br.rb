node['qubell_kubernetes']['nodes'].each_with_index do |node, i|  
  if node['ipaddress'] == node
    bash "patch docker-bridge" do
      stop docker
      ip li set dev docker0 down 
      brctl delbr docker0 
      sed -i "s/^#DOCKER_OPTS.*$/DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4 --bip=172.16.#{i}.1\/24\"/g" /etc/default/docker 
      start docker
    end
  end
end 
