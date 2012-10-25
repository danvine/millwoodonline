require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'digest/sha1'
require 'rack-flash'
require 'sinatra-authentication'
require 'sanitize'
require 'pony'
require 'builder'

use Rack::Session::Cookie, :secret => 'superdupersecret'
use Rack::Flash

configure do
    set :static, true
    set :public_folder, Proc.new { File.join(root, "public") }
    set :template_engine, :erb
    set :sinatra_authentication_view_path, Pathname(__FILE__).dirname.expand_path + "views/"
end

configure :production do
  require 'newrelic_rpm'
end

require_relative 'models'
require_relative 'helpers'
require_relative 'routes/before'
require_relative 'routes/errors'

get '/?' do
  erb :home
end

get '/about/?' do
  @title = 'About'
  erb :about
end

get '/work/?' do
  @title = 'Work'
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
  @title = 'Blog'
  erb :blog
end

get '/blog/:title/?' do
  title = Sanitize.clean(params[:title])
  @contents = Content.first(:type => 'blog', :alias => title, :fields => [:title, :body, :created, :tags])
  if @contents.nil?
    halt 404
  end
  @title = @contents.title
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
  
  if @contents.size == 0
    halt 404
  end
  
  size = @contents.size
  pager_prev = "<li class='previous'><a href='/tag/#{Sanitize.clean(params[:tag])}?page=#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/tag/#{Sanitize.clean(params[:tag])}?page=#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  @title = "#{Sanitize.clean(params[:tag].gsub('-', '%'))}"
  erb :blog
end

get '/contact/?' do
  @title = 'Contact'
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

# admin
before '/admin/*' do
  enforce_admin
end

get '/admin/content/add' do
  @title = 'Add Content'
  erb :addcontent
end

post '/admin/content/add' do
  content_attributes = params[:content]
  content_attributes['type'] = 'blog'
  content_attributes['created'] = Time.now
  content = Content.set(content_attributes)

  redirect "/blog/#{content.alias}"
end

# Feeds
get '/taxonomy/term/25/0/feed' do
  content_type 'text/xml; charset=utf8'
  tag = '%drupal%'
  @contents = Content.all(:type => 'blog', :tags.like => tag, :order => [ :created.desc ])
  
  builder :rss
end

get '/rss.xml' do
  content_type 'text/xml; charset=utf8'
  @contents = Content.all(:type => 'blog', :order => [ :created.desc ])
  
  builder :rss
end

# Redirects
get '/node/:nid/?' do
  nid = Sanitize.clean(params[:nid])
  contents = Content.first(:type => 'blog', :id => nid, :fields => [:alias])
  if contents.nil?
    halt 404
  end
  redirect '/blog/' + contents.alias, 301
end

get '/taxonomy/term/25' do
  redirect '/tag/drupal', 301
end

