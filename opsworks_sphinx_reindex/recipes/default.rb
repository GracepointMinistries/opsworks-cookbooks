#
# Cookbook Name:: sphinx
# Recipe:: default
#

include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]
  current_path = deploy[:current_path]
  shared_path = "#{deploy[:deploy_to]}/shared"
  
  is_rails_app = node[:opsworks][:instance][:layers].include?('rails-app')

  # Check to see if a migration was run during the last deployment. If so, we should validate that the sphinx reindex is working  
  if is_rails_app && deploy["migrate"]
    Chef::Log.info("indexing thinking_sphinx")
    
    execute "thinking_sphinx index" do
      command "bundle exec rake ts:index"
      user deploy[:user]
      environment({            
        'RAILS_ENV' => deploy[:rails_env]
      })
      cwd current_path
    end    
  end    
end
