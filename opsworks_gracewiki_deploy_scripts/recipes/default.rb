include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]

  Chef::Log.info("Installing chef deploy scripts to /deploy directory")

  # before_restart deploy script
  template "#{deploy[:deploy_to]}/current/deploy/before_restart.rb" do
    source "before_restart.rb.erb"  
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:release_path => "#{deploy[:deploy_to]}/current", :environment => deploy[:rails_env])
  end

  # after_restart deploy script
  template "#{deploy[:deploy_to]}/current/deploy/after_restart.rb" do
    source "after_restart.rb.erb"  
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:release_path => "#{deploy[:deploy_to]}/current", :environment => deploy[:rails_env])
  end
end