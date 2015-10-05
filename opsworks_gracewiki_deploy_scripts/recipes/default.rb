include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]

  # before_restart deploy script
  template "#{deploy[:deploy_to]}/current/deploy/before_restart.rb" do
    source "before_restart.rb.erb"  
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(:release_path => "#{deploy[:deploy_to]}/current", :environment => deploy[:rails_env])

    notifies :run, "execute[install deploy scripts: before_restart]"
  end
end