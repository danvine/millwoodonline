require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'digest/sha1'
require 'rack-flash'
require 'sinatra-authentication'
require 'sanitize'
require 'pony'

DataMapper.setup(:default, 'postgres://lbhhmtafaowdgx:tpjR5sVtWEswPaJ9tsQ7q-_cdj@ec2-54-243-233-216.compute-1.amazonaws.com:5432/d9r9mjl2refokn')
      class Content
        include DataMapper::Resource

        property :id,       Serial
        property :type,     String
        property :title,    String, :length => 256
        property :body,     Text
        property :created,  DateTime
        property :alias,    String, :length => 256
        property :tags,     String, :length => 256
      end
DataMapper.auto_upgrade!

use Rack::Session::Cookie, :secret => 'superdupersecret'
use Rack::Flash

configure do
    set :static, true
    set :public_folder, Proc.new { File.join(root, "public") }
    set :template_engine, :erb
    set :sinatra_authentication_view_path, Pathname(__FILE__).dirname.expand_path + "views/"
end

helpers do
  def pathgen(title)
    ignore = ['a', 'an', 'as', 'at', 'before', 'but', 'by', 'for', 'from', 'is', 'in', 'into', 'like', 'of', 'off', 'on', 'onto', 'per', 'since', 'than', 'the', 'this', 'that', 'to', 'up', 'via', 'with']
    title.gsub('/[^a-zA-Z0-9\/]+/', '-')
  end
end

before do
  content_type 'text/html; charset=utf8'
  expires 300, :public
 
  if request.post?
   if session[:csrf] != params[:csrf]
     halt 503, erb('<h1>500: oops</h1>')
   end
  end 
  
  time = Time.now.to_s
  @key = Digest::SHA1.hexdigest(time)
  session[:csrf] = @key
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

get '/blog/:title' do
  title = Sanitize.clean(params[:title])
  @contents = Content.first(:alias => 'blog/' + title, :fields => [:title, :body])
  erb :blog_post
end

get '/contact' do
  erb :contact
end

post '/contact' do
  options = {
  :to => 'tim@millwoodonline.co.uk',
  :from => params[:email],
  :subject => params[:name],
  :body => params[:message],
  :via => :smtp,
  :via_options => {
    :address => 'smtp.sendgrid.net',
    :port => '587',
    :domain => 'heroku.com',
    :user_name => ENV['SENDGRID_USERNAME'],
    :password => ENV['SENDGRID_PASSWORD'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
  }
  
  Pony.mail(options)
  
  flash[:notice] = "Thanks for your message."
  redirect '/contact'
end

not_found do
  erb "<h1>404: Page not found</h1>"
end

error do
  erb "<h1>500: oops</h1>"
end
