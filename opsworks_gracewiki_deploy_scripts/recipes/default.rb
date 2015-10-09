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

  # before_restart deploy script
  template "#{current_path}/deploy/before_restart.rb" do
    source "before_restart.rb.erb"  
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :release_path => current_path,
      :environment => deploy[:rails_env],
      :application => application
    )
  end

  # after_restart deploy script
  template "#{current_path}/deploy/after_restart.rb" do
    source "after_restart.rb.erb"  
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :release_path => current_path,
      :environment => deploy[:rails_env]
    )
  end
end