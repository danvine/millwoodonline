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

get '/blog/?:page?/?' do
  pass if params[:page] and !params[:page].match(/\A[0-9]+\Z/)
  html = is_cached
  if html
    return html
  end
  page = 1
  if params[:page]
    page = Integer(params[:page])
    offset = 5*page-5
    @contents = Content.all(:fields => [:title, :body, :alias, :created, :markdown], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5, :offset => offset)
    
  else
    @contents = Content.all(:fields => [:title, :body, :alias, :created, :markdown], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5)
  end
  halt 404 if @contents.empty?

  size = @contents.size
  pager_prev = "<li class='previous'><a href='/blog/#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/blog/#{page+1}'>Older &rarr;</a></li>" if size == 5
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
  halt 404 if @contents.nil?

  @title = @contents.title
  @description = "A blog post about #{@contents.tags.map{|tag| tag.tag}.join(', ')} posted on #{@contents.created.strftime("%d %B %Y")} by Tim Millwood"
  if @contents.markdown
    body = Maruku.new(@contents.body)
    @contents.body = body.to_html
  end
  n=200
  @twitter_description = Sanitize.clean(@contents.body.split(/\s+/, n+1)[0...n].join(' '))
  html = erb :blog_post
  set_cache(html)
end

get '/tag/?' do
  html = is_cached
  if html
    return html
  end
  results = ""
  tags = Tag.all(:order => [:tag.asc])
  tags.each do |tag|
    results = "#{results} <a href='/tag/#{tag.tag.gsub(' ', '-')}'>#{tag.tag}</a>"
  end
  @title = "Tags"
  @description = "All of the tags from the Millwood Online Blog posts."
  html = erb results
  set_cache(html)
end

get '/tag/:tag/?:page?/?' do
  pass if params[:page] and !params[:page].match(/\A[0-9]+\Z/)
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
  
  halt 404 if @contents.empty?
  size = @contents.size
  pager_prev = "<li class='previous'><a href='/tag/#{Sanitize.clean(params[:tag])}/#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/tag/#{Sanitize.clean(params[:tag])}/#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  @title = "#{Sanitize.clean(params[:tag]).gsub('-', ' ').capitalize}"
  @description = "Blog posts relating to #{Sanitize.clean(params[:tag]).gsub('-', ' ').capitalize}."
  html = erb :blog
  set_cache(html)
end

get '/archive' do
  html = is_cached
  if html
    return html
  end
  archive = repository(:default).adapter.select("select to_char(created, 'YYYY MM') as created_year_month, count(id) as num from contents where published = TRUE and type = 'blog' group by created_year_month order by created_year_month desc")
  results = "<ul>"
  archive.each do |month|
    month_split = month[:created_year_month].split(' ')
    results = "#{results} <li><a href='/archive/#{month_split[0]}#{month_split[1]}'>#{Date::MONTHNAMES[month_split[1].to_i]} #{month_split[0]}</a> (#{month[:num].to_s})</li>"
  end
  results = "#{results}</ul>"
  @title = "Archive"
  @description = "An archive of Millwood Online Blog posts."
  html = erb results
  set_cache(html)
end

get '/archive/:date/?:page?/?' do
  halt 404 if params[:date] and (!params[:date].match(/\A[0-9]+\Z/) or params[:date].length != 6)
  halt 404 if params[:page] and !params[:page].match(/\A[0-9]+\Z/)
  date = params[:date].scan(/.{1,4}/).map {|id| id.to_i }
  html = is_cached
  if html
    return html
  end
  page = 1
  if params[:page]
    page = params[:page].to_i
    offset = 5*page-5
    @contents = Content.all(:fields => [:title, :body, :alias, :created, :markdown], :conditions => [ 'created >= ? and created < ?', "#{date[0]}-#{date[1]}-01", "#{date[0]}-#{date[1]+1}-01"], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5, :offset => offset)
    
  else
    @contents = Content.all(:fields => [:title, :body, :alias, :created, :markdown], :conditions => [ 'created >= ? and created < ?', "#{date[0]}-#{date[1]}-01", "#{date[0]}-#{date[1]+1}-01"], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5)
  end
  halt 404 if @contents.empty?

  size = @contents.size
  pager_prev = "<li class='previous'><a href='/archive/#{params[:date]}/#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/archive/#{params[:date]}/#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  @title = "Archive - #{Date::MONTHNAMES[date[1]]} #{date[0]}"
  @description = "Archive of blog posts from #{Date::MONTHNAMES[date[1]]} #{date[0]} featuring topics such as Drupal, Ruby-on-Rails, Sinatra and web development."
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

get '/rip-drippic' do
  @title = "R.I.P Drippic"
  @description = "Drippic has closed."
  erb '<p>Sorry, Drippic has closed.</p><p>The code is still available on <a href="http://drupal.org/project/drippic">Drupal.org</a> if you really want it.</p>'
end