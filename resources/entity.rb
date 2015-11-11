actions :create, :delete, :clean, :clean_svc
default_action :create

attribute :name,       :kind_of => String, :name_attribute => true
attribute :uris,       :kind_of => Array 
attribute :master,     :kind_of => String
