include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]
  current_path = deploy[:current_path]

  Chef::Log.info("Installing chef deploy scripts to /deploy directory")

  # before_restart deploy script
  template "#{current_path}/deploy/before_restart.rb" do
    source "before_restart.rb.erb"  
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:release_path => current_path, :environment => deploy[:rails_env])
  end

  # after_restart deploy script
  template "#{current_path}/deploy/after_restart.rb" do
    source "after_restart.rb.erb"  
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:release_path => current_path, :environment => deploy[:rails_env])
  end
end