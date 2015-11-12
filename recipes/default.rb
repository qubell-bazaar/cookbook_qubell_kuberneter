#
# Cookbook Name:: qubell-mesos
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
require 'yaml'

case node['platform_family']
  when "debian"
    bash "update packages cache" do
      code <<-EOH
         apt-get update
      EOH
    end
  end
directory "#{node['qubell_kubernetes']['home']}" do
  action :create
end
git "#{node['qubell_kubernetes']['home']}/repo" do
  repository "https://github.com/GoogleCloudPlatform/kubernetes"
  revision 'release-1.1'
  action :sync
end

bash "build kubernetes" do
   cwd "#{node['qubell_kubernetes']['home']}/repo"
   code <<-EOH
     make clean; make 
     EOH
   environment(
    'KUBERNETES_CONTRIB' => "mesos"
   )
end
docker_image 'quay.io/coreos/etcd' do
  tag 'v2.0.12'
  action :pull
  notifies :redeploy, 'docker_container[etcd]'
end

docker_container 'etcd' do
  repo 'quay.io/coreos/etcd'
  port ['4001:4001', '7001:7001']
  command "--listen-client-urls http://0.0.0.0:4001 --advertise-client-urls http://#{node['ipaddress']}:4001"
  detach true
  hostname node['fqdn']
  tag "v2.0.12"
  action :run
end

template ::File.join(node['qubell_kubernetes']['home'], "/mesos-cloud.conf") do
  source "mesos-cloud.conf.erb"
  variables({
     :zk_nodes => node["qubell_kubernetes"]["zk_hosts"].join(',')
  })  
end

svc = ['apiserver', 'controller-manager', 'scheduler']

for s in svc
  case s
    when 'apiserver'
      flags = "--address=#{node['ipaddress']} --etcd-servers=http://#{node['ipaddress']}:4001 --service-cluster-ip-range=10.10.127.0/24 --insecure-port=#{node['qubell_kubernetes']['port']} --cloud-provider=mesos --cloud-config=#{node['qubell_kubernetes']['home']}/mesos-cloud.conf --v=1 > #{node['qubell_kubernetes']['home']}/apiserver.log 2>&1"
    when 'controller-manager'
      flags = "--master=#{node['ipaddress']}:#{node['qubell_kubernetes']['port']} --cloud-provider=mesos --cloud-config=#{node['qubell_kubernetes']['home']}/mesos-cloud.conf --v=1 >#{node['qubell_kubernetes']['home']}/controller.log 2>&1"
    when 'scheduler'
      flags = "--address=#{node['ipaddress']} --mesos-master=zk://#{node['qubell_kubernetes']['zk_hosts'].join(',')}/mesos --etcd-servers=http://#{node['ipaddress']}:4001 --mesos-user=root --api-servers=#{node['ipaddress']}:#{node['qubell_kubernetes']['port']} --v=2 --executor-logv=5  >#{node['qubell_kubernetes']['home']}/scheduler.log 2>&1"
  end 
  template "kube-#{s}-wrapper" do 
    path "#{node['qubell_kubernetes']['home']}/start-#{s}"
    source 'wrapper.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables({
        :svc => s,
        :flags => flags
     })
  end

  template "kube-#{s}-init" do
    path   "/etc/init/kube-#{s}.conf"
    source 'upstart.erb'
    owner 'root'
    group 'root'
    variables({
       :name => "Start kubernetes-#{s}",
       :wrapper => "#{node['qubell_kubernetes']['home']}/start-#{s}"
    })
  end

  service "kube-#{s}" do
    provider Chef::Provider::Service::Upstart
    supports status: true, restart: true
    subscribes :restart, "template[kube-#{s}-init]"
    subscribes :restart, "template[kube-#{s}-wrapper]"
    action [:enable, :start]
    not_if 'sleep 1', :timeout => 10
  end
end
