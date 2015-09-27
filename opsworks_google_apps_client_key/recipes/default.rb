# Add the client.p12 file

if node[:opsworks][:instance][:layers].include?('rails-app')
  node[:deploy].each do |application, deploy|
    current_path = deploy[:current_path]
    
    # create private key
    remote_file "#{current_path}/public/client.p12" do
      source "client.p12"      
      mode 0655
    end
  end
end
