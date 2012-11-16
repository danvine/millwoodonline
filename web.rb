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
require_relative 'routes/feeds'
require_relative 'routes/admin'

get '/?' do
  html = is_cached
  if html
    return html
  end
  @contents = Content.first(:fields => [:title, :alias, :created], :type => 'blog', :published => true, :order => [ :created.desc ])
  html = erb :home
  set_cache(html)
end

get '/about/?' do
  @title = 'About'
  @description = 'Tim Millwood is a web developer based in Cardiff / Abergavenny, Wales, UK working on Drupal, Ruby-on-Rails and Sinatra.'
  cache_url(3600, true) {erb :about}
end

get '/work/?' do
  @title = 'Work'
  @description = 'Tim Millwood currently works at Acquia as a Client advisor. He is also taking on Drupal, Ruby-on-Rals and Sinatra freelance website design and development projects.'
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
    @contents = Content.all(:fields => [:title, :body, :alias, :created], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5, :offset => offset)
    
  else
    @contents = Content.all(:fields => [:title, :body, :alias, :created], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5)
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
  @description = "Call 01873 878587 or email Tim Millwood."
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
  @description = "Tim Millwood is a PHP and Drupal developer working in Cardiff / Abergavenny, Wales, UK offering website design and development."
  erb :php
end

get '/ruby-on-rails-sinatra-web-developer-cardiff-abergavenny-wales-uk' do
  @head_title = "Ruby on Rails / Sinatra Web Developer based in Cardiff / Abergavenny, Wales, UK"
  @description = "Tim Millwood is a Ruby-on-Rails and Sinatra developer working in Cardiff / Abergavenny, Wales, UK offering website design and development."
  erb :ruby
end

require_relative 'routes/redirects'