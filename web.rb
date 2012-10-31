require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'digest/sha1'
require 'rack-flash'
require 'sinatra-authentication'
require 'sanitize'
require 'pony'
require 'builder'
require 'rack/csrf'
require 'redis'

use Rack::Session::Cookie, :secret => ENV['SECRET']
use Rack::Flash
use Rack::Csrf, :raise => true

configure do
    set :template_engine, :erb
    set :sinatra_authentication_view_path, Pathname(__FILE__).dirname.expand_path + "views/"
    
    uri = URI.parse(ENV["REDISTOGO_URL"])
    REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

configure :production do
  require 'newrelic_rpm'
end

require_relative 'models'
require_relative 'helpers'
require_relative 'routes/before'
require_relative 'routes/errors'

get '/?' do
  cache_url(3600, true) {erb :home}
end

get '/about/?' do
  @title = 'About'
  cache_url(3600, true) {erb :about}
end

get '/work/?' do
  @title = 'Work'
  cache_url(3600, true) {erb :work}
end

get '/blog/?' do
  html = is_cached
  if html
    return html
  end
  page = 1
  if params[:page]
    page = Integer(params[:page])
    offset = 5*page-5
    @contents = Content.all(:type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5, :offset => offset)
    
  else
    @contents = Content.all(:type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5)
  end
  
  size = @contents.size
  pager_prev = "<li class='previous'><a href='/blog?page=#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/blog?page=#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  @title = 'Blog'
  html = erb :blog
  set_cache(html)
end

get '/blog/:title/?' do
  title = Sanitize.clean(params[:title])
  if current_user.admin?
    @contents = Content.first(:type => 'blog', :alias => title, :fields => [:title, :body, :created, :tags])
  else
    @contents = Content.first(:type => 'blog', :published => true, :alias => title, :fields => [:title, :body, :created, :tags])
  end
  if @contents.nil?
    halt 404
  end
  @title = @contents.title
  etag Digest::SHA1.hexdigest(@contents.body)
  erb :blog_post
end

get '/tag/:tag/?' do
  page = 1
  tag = "%#{Sanitize.clean(params[:tag].gsub('-', '%'))}%"
  if params[:page]
    page = Integer(params[:page])
    offset = 5*page-5
    @contents = Content.all(:type => 'blog', :published => true, :tags.like => tag, :order => [ :created.desc ], :limit => 5, :offset => offset)
    
  else
    @contents = Content.all(:type => 'blog', :published => true, :tags.like => tag, :order => [ :created.desc ], :limit => 5)
  end
  
  if @contents.size == 0
    halt 404
  end
  
  size = @contents.size
  pager_prev = "<li class='previous'><a href='/tag/#{Sanitize.clean(params[:tag])}?page=#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/tag/#{Sanitize.clean(params[:tag])}?page=#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  @title = "#{Sanitize.clean(params[:tag].gsub('-', '%'))}"
  etag Digest::SHA1.hexdigest(@contents.first.body)
  erb :blog
end

get '/contact/?' do
  @title = 'Contact'
  cache_url(3600, true) {erb :contact}
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

get '/admin/content/?' do
  @contents = Content.all(:order => [ :created.desc ])
  @title = 'Content'
  erb :content
end

get '/admin/content/edit/:id/?' do
  id = Sanitize.clean(params[:id])
  @contents = Content.first(:order => [ :created.desc ], :id => id)
  @title = "Edit '#{@contents.title}'"
 
  erb :addcontent
end

post '/admin/content/edit/:id/?' do
  content_attributes = params[:content]
  content_attributes['created'] = Time.now
  id = Sanitize.clean(params[:id])
  content = Content.get(id)
  content.body = content_attributes['body']
  content.published = content_attributes['published']
  content.created = Time.now
  content.save
  redirect "/admin/content/edit/#{id}"
end

get '/admin/content/add/?' do
  @title = 'Add Content'
  erb :addcontent
end

post '/admin/content/add/?' do
  content_attributes = params[:content]
  content_attributes['type'] = 'blog'
  content_attributes['created'] = Time.now
  content = Content.create(content_attributes)
  if content.published?
    redirect "/blog/#{content.alias}"
  else
    redirect "/admin/content"
  end  
end

# Feeds
get '/taxonomy/term/25/0/feed/?' do
  content_type 'text/xml; charset=utf8'
  page = is_cached
  if page
    return page
  else
    tag = '%drupal%'
    @contents = Content.all(:type => 'blog', :published => true, :tags.like => tag, :order => [ :created.desc ])
    page = builder :rss
    set_cache(page)
  end
end

get '/rss.xml' do
  content_type 'text/xml; charset=utf8'
  page = is_cached
  if page
    return page
  else
    @contents = Content.all(:type => 'blog', :published => true, :order => [ :created.desc ])
    page = builder :rss
    set_cache(page)
  end
end

# Redirects
get '/node/:nid/?' do
  nid = Sanitize.clean(params[:nid])
  contents = Content.first(:type => 'blog', :published => true, :id => nid, :fields => [:alias])
  if contents.nil?
    halt 404
  end
  redirect '/blog/' + contents.alias, 301
end

get '/taxonomy/term/25/?' do
  redirect '/tag/drupal', 301
end

