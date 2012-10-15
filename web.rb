require 'rubygems'
require 'sinatra'
require "dm-core"
require "dm-migrations"
require "digest/sha1"
require 'rack-flash'
require "sinatra-authentication"
DataMapper.setup(:default, 'postgres://lbhhmtafaowdgx:tpjR5sVtWEswPaJ9tsQ7q-_cdj@ec2-54-243-233-216.compute-1.amazonaws.com:5432/d9r9mjl2refokn')
DataMapper.auto_upgrade!
use Rack::Session::Cookie, :secret => 'superdupersecret'
use Rack::Flash

configure do
    set :static, true
    set :public_folder, Proc.new { File.join(root, "public") }
    set :template_engine, :erb
    set :sinatra_authentication_view_path, Pathname(__FILE__).dirname.expand_path + "views/"
end

get '/' do
  erb :home
end
