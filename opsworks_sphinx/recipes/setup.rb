#
# Cookbook Name:: sphinx
# Recipe:: setup
#

include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]
  current_path = deploy[:current_path]
  shared_path = "#{deploy[:deploy_to]}/shared"
  
  is_rails_app = node[:opsworks][:instance][:layers].include?('rails-app')

  # If you want to have scheduled reindexes in cron, enter the minute
  # interval here. This is passed directly to cron via /, so you should
  # only use numbers between 1 - 59.
  #
  # If you don't want scheduled reindexes, just leave this set to nil.
  # Setting it equal to 10 would run the cron job every 10 minutes.

  cron_interval = 10 #If this is not set your data will NOT be indexed

  # Get the sphinx host from the Sphinx layer 
  sphinx_host = '127.0.0.1'
  
  if is_rails_app
    Chef::Log.info("configuring thinking_sphinx")
    
    directory "/data/sphinx/#{application}/indexes" do
      recursive true
      owner deploy[:user]
      group deploy[:group]
      mode 0755
    end

    directory "/var/run/sphinxsearch" do
      owner deploy[:user]
      group deploy[:group]
      mode 0755
    end

    directory "/var/log/sphinxsearch/#{application}" do
      recursive true
      owner deploy[:user]
      group deploy[:group]
      mode 0755
    end

    cookbook_file "#{shared_path}/scripts/thinking_sphinx_searchd" do
      owner deploy[:user]
      group deploy[:group]
      mode 0655
      source "thinking_sphinx_searchd"            
    end
    
    template "/etc/monit/monitrc.d/sphinx.#{application}" do
      source "sphinx.erb"
      owner deploy[:user]
      group deploy[:group]
      mode 0644
      variables({
        :application => application,
        :user => 'root'
      })
    end

    execute "monit reload"

    if cron_interval
      cron "sphinx index" do
        action  :create
        minute  "*/#{cron_interval}"
        hour    '*'
        day     '*'
        month   '*'
        weekday '*'
        command "cd #{current_path} && RAILS_ENV=#{deploy[:rails_env]} bundle exec rake ts:index"
        user deploy[:user]
      end
    end

    directory "#{shared_path}/config/sphinx" do
      recursive true
      owner deploy[:user]
      group deploy[:group]
      mode 0755
    end

    template "#{shared_path}/config/thinking_sphinx.yml" do
      owner deploy[:user]
      group deploy[:group]
      mode 0644
      source "thinking_sphinx.yml.erb"
      variables({
        :application => application,
        :release_path => current_path,
        :environment => deploy[:rails_env],
        :address => sphinx_host,
        :user => deploy[:user],
        :mem_limit => '512M'
      })
    end

    execute "sphinx config" do
      command "bundle exec rake ts:configure"
      user deploy[:user]
      environment({          
        'RAILS_ENV' => deploy[:rails_env]
      })
      cwd current_path
    end
  end    
end
