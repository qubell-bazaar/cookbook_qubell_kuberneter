$:.unshift *Dir[::File.expand_path('../../files/default/vendor/gems/**/lib', __FILE__)]
require 'fileutils'
require 'yaml'
require 'kubeclient'

action :create do
  @new_resource.uris.each_with_index do |uri, i|

    remote_file "/tmp/entity-#{i}.yaml" do
      source "#{uri}"
    end

    ruby_block "query /tmp/entity-#{i}.yaml" do
      block do
        file = YAML.load_file("/tmp/entity-#{i}.yaml")
        client = Kubeclient::Client.new "http://#{new_resource.master}:#{node['qubell_kubernetes']['port']}/api/"
        kind = file['kind']
        entity_name = file['metadata']['name']
        kind = file['kind']
          case kind 
            when "Pod"
              entity = client.get_pod
            when "Service"
              entity = client.get_service
            when "ReplicationController"
              entity = "client.get_replication_controller"
            when "Secret"
              entity = client.get_secret
            end
        begin
          entity(entity_name, "default")
          Chef::Log.info("#{kind} #{entity_name} already exists")
        rescue
          FileUtils.mv("/tmp/entity-#{i}.yaml", "/tmp/to_install/#{entity_name}.yaml")
        end
      end
    end

  end
  bash "create entity #{new_resource.name}" do
    code <<-EOH
         kubectl --server=#{new_resource.master}:#{node['qubell_kubernetes']['port']} create -f /tmp/to_install/
         mv /tmp/to_install/* /tmp/resource_installed/
    EOH
    environment(
        'PATH' => "#{node['qubell_kubernetes']['home']}/repo/_output/local/go/bin:#{ENV['PATH']}"
    )
  end
end

action :delete do

  @new_resource.uris.each_with index do |uri, i|

    remote_file "/tmp/entity.yaml-#{i}" do
      source "#{uri}"
    end

    ruby_block "query /tmp/entity-#{i}.yaml" do
      block do
        file = YAML.load_file("/tmp/entity-#{i}.yaml")
        client = Kubeclient::Client.new "http://#{new_resource.master}:#{node['qubell_kubernetes']['port']}/api/"
        kind = file['kind']
        entity_name = file['metadata']['name']
        kind = file['kind']
          case kind 
            when "Pod"
              entity = client.get_pod
            when "Service"
              entity = client.get_service
            when "ReplicationController"
              entity = client.get_replication_controller
            when "Secret"
              entity = client.get_secret
            end
        begin
          entity(entity_name, "default")
          File.rm_f('/tmp/entity.yaml') if File.exist?("/tmp/entity.yaml")
          File.rm_f("/tmp/resource_installed/#{entity_name}.yaml") if File.exist?("/tmp/resource_installed/#{entity_name}.yaml")
        rescue
          Chef::Log.info "#{kind} #{entity_name} do not exists - nothing to do."
        end
      end
    end
  end
end



action :clean do
  bash "delete_rc_po" do
    code <<-EOH
         kubectl --server=#{new_resource.master}:#{node['qubell_kubernetes']['port']} delete rc --all
         kubectl --server=#{new_resource.master}:#{node['qubell_kubernetes']['port']} delete po --all 
    EOH
    environment(
        'PATH' => "#{node['qubell_kubernetes']['home']}/repo/_output/local/go/bin:#{ENV['PATH']}"
    )
  end

end


action :clean_svc do
  bash "delete_svc" do
    code <<-EOH
         kubectl --server=#{new_resource.master}:#{node['qubell_kubernetes']['port']} delete rc --all
         kubectl --server=#{new_resource.master}:#{node['qubell_kubernetes']['port']} delete po --all
         kubectl --server=#{new_resource.master}:#{node['qubell_kubernetes']['port']} delete svc --all
    EOH
    environment(
        'PATH' => "#{node['qubell_kubernetes']['home']}/repo/_output/local/go/bin:#{ENV['PATH']}"
    )
  end

end

