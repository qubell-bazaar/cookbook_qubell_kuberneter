node['qubell-kubernetes']['nodes'].each_with_index do |n, i|  
  case n
    when node['ipaddress']
      bash "patch docker-bridge" do
        code <<-EOF
          stop docker &&
          ip li set dev docker0 down 
          brctl delbr docker0 
          sed -i 's@^#DOCKER_OPTS.*$@DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4 --bip=172.16.#{i}.1/24\"@g' /etc/default/docker 
          start docker
          EOF
      end
    end
end 
