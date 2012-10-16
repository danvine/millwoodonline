require 'rubygems'
require 'sinatra'
require "dm-core"
require "dm-migrations"
require "digest/sha1"
#require 'rack-flash'
require "sinatra-authentication"


DataMapper.setup(:default, 'postgres://lbhhmtafaowdgx:tpjR5sVtWEswPaJ9tsQ7q-_cdj@ec2-54-243-233-216.compute-1.amazonaws.com:5432/d9r9mjl2refokn')
      class Content
        include DataMapper::Resource

        property :id,         Serial    # An auto-increment integer key
        property :type,      String    # A varchar type string, for short strings
        property :title,      String    # A varchar type string, for short strings
        property :body,       Text      # A text block, for longer string data.
        property :created, DateTime  # A DateTime, for any date you might like.
        property :alias,      String    # A varchar type string, for short strings
        property :tags,      String    # A varchar type string, for short strings
      end
DataMapper.auto_upgrade!

use Rack::Session::Cookie, :secret => 'superdupersecret'
#use Rack::Flash

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
  @contents = Content.all(:order => [ :id.desc ])
  erb :blog
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
