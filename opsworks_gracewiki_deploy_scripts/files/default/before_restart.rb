rails_env = new_resource.environment["RAILS_ENV"]

# Update whenever jobs.
run "cd #{release_path}; bundle exec whenever --set environment=#{rails_env} --update-crontab gracewiki"