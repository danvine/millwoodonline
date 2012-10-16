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

before do
  content_type 'text/html; charset=utf8'
  expires 300, :public
end

get '/' do
  erb :home
end

get '/about' do
  erb :home
end

get '/work' do
  erb :home
end

get '/blog' do
  erb :home
end

get '/contact' do
  erb :home
end

post '/contact' do
  erb :home
end

not_found do
  erb "<h1>404: Page not found</h1>"
end
