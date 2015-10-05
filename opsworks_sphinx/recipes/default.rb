#
# Cookbook Name:: sphinx
# Recipe:: default
#

include_recipe "deploy"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]
  current_path = deploy[:current_path]

  # Uncomment the flavor of sphinx you want to use
  flavor = "thinking_sphinx"
  #flavor = "ultrasphinx"
  
  is_sphinx_instance = node[:opsworks][:instance][:layers].include?('sphinx')
  is_rails_app = node[:opsworks][:instance][:layers].include?('rails-app')

  # If you want to have scheduled reindexes in cron, enter the minute
  # interval here. This is passed directly to cron via /, so you should
  # only use numbers between 1 - 59.
  #
  # If you don't want scheduled reindexes, just leave this set to nil.
  # Setting it equal to 10 would run the cron job every 10 minutes.

  cron_interval = 10 #If this is not set your data will NOT be indexed

  
  sphinx_host = node["opsworks"]["layers"]["sphinx"]["instances"][0]["private_dns_name"]
  
  if is_sphinx_instance
    Chef::Log.info("configuring #{flavor}")
    
    directory "/data/sphinx/#{application}/indexes" do
      recursive true
      owner deploy[:user]
      group deploy[:group]
      mode 0755
    end

    directory "/var/run/sphinx" do
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

    remote_file "/etc/logrotate.d/sphinx" do
      owner "root"
      group "root"
      mode 0755
      source "sphinx.logrotate"
      backup false
      action :create
    end

    template "/etc/monit/monitrc.d/sphinx.#{application}" do
      source "sphinx.erb"
      owner deploy[:user]
      group deploy[:group]
      mode 0644
      variables({
        :application => application,
        :user => deploy[:user],
        :flavor => flavor
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
        command "cd /data/#{application}/current && RAILS_ENV=#{deploy[:rails_env]} bundle exec rake #{flavor}:index"
        user deploy[:user]
      end
    end
  end

  if is_rails_app
    directory "#{deploy[:deploy_to]}/shared/config/sphinx" do
      recursive true
      owner deploy[:user]
      group deploy[:group]
      mode 0755
    end

    template "#{deploy[:deploy_to]}/shared/config/sphinx.yml" do
      owner deploy[:user]
      group deploy[:group]
      mode 0644
      source "sphinx.yml.erb"
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
      command "bundle exec rake #{flavor}:configure"
      user deploy[:user]
      environment({          
        'RAILS_ENV' => deploy[:rails_env]
      })
      cwd current_path
    end

    Chef::Log.info("indexing #{flavor}")

    # Check to see if a migration was run during the last deployment. If so, we should validate that the sphinx reindex is working
    if deploy["migrate"]
      execute "#{flavor} index" do
        command "bundle exec rake #{flavor}:index"
        user deploy[:user]
        environment({            
          'RAILS_ENV' => deploy[:rails_env]
        })
        cwd current_path
      end
    end          
  end    
end
