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
  @description = 'Tim Millwood is a web developer based in Cardiff / Abergavenny, Wales, UK working on Drupal, Ruby-on-Rails and Sinatra.'
  cache_url(3600, true) {erb :about}
end

get '/work/?' do
  @title = 'Work'
  @description = 'Tim Millwood currently works at Acquia as a Client advisor. He is also taking on Drupal, Ruby-on-Rals and Sinatra freelance web development projects.'
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
    @contents = Content.all(:fields => [:title, :body, :alias], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5, :offset => offset)
    
  else
    @contents = Content.all(:fields => [:title, :body, :alias], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5)
  end
  
  size = @contents.size
  pager_prev = "<li class='previous'><a href='/blog?page=#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/blog?page=#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  @title = 'Blog'
  @description = 'Millwood Online Blog features many articles on Drupal, Ruby-on-Rails, Sinatra and related Web Development topics.'
  html = erb :blog
  set_cache(html)
end

get '/blog/:title/?' do
  html = is_cached
  if html
    return html
  end
  title = Sanitize.clean(params[:title])
  if current_user.admin?
    @contents = Content.first(:type => 'blog', :alias => title)
  else
    @contents = Content.first(:type => 'blog', :published => true, :alias => title)
  end
  if @contents.nil?
    halt 404
  end

  @title = @contents.title
  @description = "A blog post about #{@contents.tags.map{|tag| tag.tag}.join(', ')} posted on #{@contents.created.strftime("%d %B %Y")} by Tim Millwood"
  html = erb :blog_post
  set_cache(html)
end

get '/tag/:tag/?' do
  html = is_cached
  if html
    return html
  end
  page = 1
  tag = Sanitize.clean(params[:tag].gsub('-', ' '))
  tag_id = Tag.first(:tag => tag)
  if !tag_id
    halt 404
  end
  if params[:page]
    page = Integer(params[:page])
    offset = 5*page-5
    @contents = Content.all(:type => 'blog', :published => true, :content_tags => {:tag_id => tag_id.id}, :order => [ :created.desc ], :limit => 5, :offset => offset)
    
  else
    @contents = Content.all(:type => 'blog', :published => true, :content_tags => {:tag_id => tag_id.id}, :order => [ :created.desc ], :limit => 5)
   end
  
  if @contents.size == 0
    halt 404
  end
  
  size = @contents.size
  pager_prev = "<li class='previous'><a href='/tag/#{Sanitize.clean(params[:tag])}?page=#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/tag/#{Sanitize.clean(params[:tag])}?page=#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  @title = "#{Sanitize.clean(params[:tag]).gsub('-', ' ').capitalize}"
  @description = "Blog posts relating to #{Sanitize.clean(params[:tag]).gsub('-', ' ').capitalize}."
  html = erb :blog
  set_cache(html)
end

get '/contact/?' do
  @title = 'Contact'
  @description "Call 01873 878587 or email Tim Millwood."
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

get '/php-drupal-web-developer-cardiff-abergavenny-wales-uk' do
  @head_title = "PHP / Drupal Web Developer based in Cardiff / Abergavenny, Wales, UK"
  @description = "Tim Millwood is a PHP and Drupal developer working in Cardiff / Abergavenny, Wales, UK."
  erb :php
end

get '/ruby-on-rails-sinatra-web-developer-cardiff-abergavenny-wales-uk' do
  @head_title = "Ruby on Rails / Sinatra Web Developer based in Cardiff / Abergavenny, Wales, UK"
  @description = "Tim Millwood is a Ruby-on-Rails and Sinatra developer working in Cardiff / Abergavenny, Wales, UK."
  erb :ruby
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
  content_attributes['tags'].split(',').each do |tag|
    tag_data = Tag.first_or_create(:tag => tag.lstrip.rstrip)
    content.tags << tag_data
  end
  content.title = content_attributes['title']
  content.type = 'blog'
  content.legacy_tags = content_attributes['tags']
  content.body = content_attributes['body']
  content.alias = content_attributes['alias']
  content.published = content_attributes['published']? true : false
  content.created = Time.now if content_attributes['update_created']
  content.save
  redirect "/admin/content/edit/#{id}"
end

get '/admin/content/add/?' do
  @title = 'Add Content'
  erb :addcontent
end

post '/admin/content/add/?' do
  content_attributes = params[:content]
  content = Content.create
  content_attributes['tags'].split(',').each do |tag|
    tag_data = Tag.first_or_create(:tag => tag.lstrip.rstrip)
    content.tags << tag_data
  end
  content.title = content_attributes['title']
  content.type = 'blog'
  content.legacy_tags = content_attributes['tags']
  content.body = content_attributes['body']
  content.alias = content_attributes['alias']
  content.published = content_attributes['published']? true : false
  content.created = Time.now if content_attributes['update_created']
  content.save

  if content_attributes['published']
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
  end
  
  @contents = Content.all(:type => 'blog', :published => true, :content_tags => {:tag_id => Tag.first(:tag => 'drupal').id}, :order => [ :created.desc ], :limit => 10)
  page = builder :rss
  set_cache(page)
end

get '/rss.xml' do
  content_type 'text/xml; charset=utf8'
  page = is_cached
  if page
    return page
  end
  
  @contents = Content.all(:fields => [:title, :body, :created, :alias], :type => 'blog', :published => true, :limit => 10, :order => [ :created.desc ])
  page = builder :rss
  set_cache(page)
end

# Redirects
get '/node/:nid/?' do
  nid = Sanitize.clean(params[:nid])
  contents = Content.first(:fields => [:alias], :type => 'blog', :published => true, :id => nid)
  if contents.nil?
    halt 404
  end
  redirect '/blog/' + contents.alias, 301
end

get '/tags/*' do
  redirect '/tag/' + params[:splat].first
end

get '/taxonomy/term/25/?' do
  redirect '/tag/drupal', 301
end

get '/:alias/?' do
  url_alias = Sanitize.clean(params[:alias])
  contents = Content.first(:fields => [:alias], :type => 'blog', :published => true, :alias => url_alias)
  if contents.nil?
    halt 404
  end
  redirect '/blog/' + contents.alias, 301
end