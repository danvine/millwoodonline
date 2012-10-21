require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'digest/sha1'
require 'rack-flash'
require 'sinatra-authentication'
require 'sanitize'
require 'pony'
require 'builder'

DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_SILVER_URL'])
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
  
  def blockload
    @block = erb :block, :layout => false
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
  
  blockload
end

get '/?' do
  erb :home
end

get '/about/?' do
  erb :about
end

get '/work/?' do
  erb :work
end

get '/blog/?' do
  page = 1
  if params[:page]
    page = Integer(params[:page])
    offset = 5*page-5
    @contents = Content.all(:type => 'blog', :order => [ :created.desc ], :limit => 5, :offset => offset)
    
  else
    @contents = Content.all(:type => 'blog', :order => [ :created.desc ], :limit => 5)
  end
  
  size = @contents.size
  pager_prev = "<li class='previous'><a href='/blog?page=#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/blog?page=#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  erb :blog
end

get '/blog/:title/?' do
  title = Sanitize.clean(params[:title])
  @contents = Content.first(:type => 'blog', :alias => title, :fields => [:title, :body, :created, :tags])
  erb :blog_post
end

get '/tag/:tag/?' do
  page = 1
  tag = "%#{Sanitize.clean(params[:tag].gsub('-', '%'))}%"
  if params[:page]
    page = Integer(params[:page])
    offset = 5*page-5
    @contents = Content.all(:type => 'blog', :tags.like => tag, :order => [ :created.desc ], :limit => 5, :offset => offset)
    
  else
    @contents = Content.all(:type => 'blog', :tags.like => tag, :order => [ :created.desc ], :limit => 5)
  end
  
  size = @contents.size
  pager_prev = "<li class='previous'><a href='/tag/#{Sanitize.clean(params[:tag])}?page=#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/tag/#{Sanitize.clean(params[:tag])}?page=#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  erb :blog
end

get '/contact/?' do
  erb :contact
end

post '/contact/?' do
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
  
  flash[:notice] = "Thank you for your message."
  redirect '/contact'
end

# Feeds
get '/taxonomy/term/25/0/feed' do
  tag = '%drupal%'
  @contents = Content.all(:type => 'blog', :tags.like => tag, :order => [ :created.desc ])
  
  builder :rss
end

get '/rss.xml' do
  @contents = Content.all(:type => 'blog', :order => [ :created.desc ])
  
  builder :rss
end

# Redirects
get '/node/:nid/?' do
  nid = Sanitize.clean(params[:nid])
  contents = Content.first(:type => 'blog', :id => nid, :fields => [:alias])
  redirect '/blog/' + contents.alias
end

get '/taxonomy/term/25' do
  redirect '/tag/drupal'
end

# Errors
not_found do
  erb "<h1>404: Page not found</h1>"
end

error do
  erb "<h1>500: oops</h1>"
end
