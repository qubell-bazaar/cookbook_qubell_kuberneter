directory "/tmp/to_install/"
directory "/tmp/resource_installed/"
qubell_kubernetes_entity node['qubell_kubernetes']['entity']['name'] do
  action :"#{node['qubell_kubernetes']['entity']['action']}"
  master node['qubell_kubernetes']['master']
  uris node['qubell_kubernetes']['entity']['uris']
end
