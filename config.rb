configure do
    set :template_engine, :erb
    set :sinatra_authentication_view_path, Pathname(__FILE__).dirname.expand_path + "views/"
    set :public_folder, Pathname(__FILE__).dirname.expand_path + "public/"
    set :static_cache_control, [:public, {:max_age => 3600}]
    
    uri = URI.parse(ENV["REDISTOGO_URL"])
    REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

configure :production do
  require 'newrelic_rpm'
end