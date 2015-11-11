packages = ['ruby-dev', 'make', 'gcc', 'g++', 'build-essential', 'git', 'bridge-utils']
for p in packages
      package p
end
debs = ['docker-engine_1.8.2-0~trusty_amd64.deb', 'golang-src_1.3-3_amd64.deb', 'golang-go-linux-amd64_1.3-3_amd64.deb', 'golang-go_1.3-3_amd64.deb', 'vim-syntax-go_1.3-3_all.deb']
directory '/tmp/deps' do
      action :create
end
for d in debs
  remote_file "/tmp/deps/#{d}" do
    source "https://s3.amazonaws.com/qubell-starter-kit-artifacts/deps/Kubernetes/#{d}"
  end
  package d do
    source "/tmp/deps/#{d}"
    provider Chef::Provider::Package::Dpkg
  end
end
#execute "install docker.io" do 
 # command "wget -qO- https://get.docker.com/ | sh"
#end
chef_gem 'kubeclient' do
    action :install
    compile_time false 
end
