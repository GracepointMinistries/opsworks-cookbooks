include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]
  current_path = deploy[:current_path]
  shared_path = "#{deploy[:deploy_to]}/shared"

  Chef::Log.info("Installing chef deploy scripts to /deploy directory")
  
  # create shared directory for assets, if it doesn't exist
  directory "#{shared_path}/assets" do
    mode 0770
    action :create
    recursive true
  end

  # create deploy directory for assets, if it doesn't exist
  directory "#{shared_path}/deploy" do
    mode 0770
    action :create
    recursive true
  end

  # before_restart deploy script
  cookbook_file "#{shared_path}/deploy/before_restart.rb" do
    owner deploy[:user]
    group deploy[:group]
    mode 0660
    source "before_restart.rb"            
  end
 
  # after_restart deploy script
    cookbook_file "#{shared_path}/deploy/after_restart.rb" do
    owner deploy[:user]
    group deploy[:group]
    mode 0660
    source "after_restart.rb"            
  end
