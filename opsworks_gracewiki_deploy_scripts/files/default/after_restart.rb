rails_env = new_resource.environment["RAILS_ENV"]

run "sudo /etc/init.d/memcached restart &"

# Restart sphinx
run "cd #{release_path}; bundle exec rake ts:restart RAILS_ENV=#{rails_env}"
