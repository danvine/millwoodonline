get '/?' do
  html = is_cached
  if html
    return html
  end
  @contents = Content.first(:type => 'blog', :published => true, :order => [ :created.desc ])
  if @contents and @contents.markdown
    @contents.body = RDiscount.new(@contents.body).to_html
  end
  html = erb File.read './views/home.erb'
  set_cache(html)
end

get '/about/?' do
  html = is_cached
  if html
    return html
  end
  @title = 'About'
  @description = 'Tim Millwood is a web developer based in Cardiff / Abergavenny, Wales, UK working on Drupal, Ruby-on-Rails and Sinatra.'
  html = erb File.read './views/about.erb;
  set_cache(html)
end

get '/work/?' do
  html = is_cached
  if html
    return html
  end
  @title = 'Work'
  @description = 'Tim Millwood currently works at Acquia as a Client advisor. He is also taking on Drupal, Ruby-on-Rals and Sinatra freelance website design and development projects.'
  html = erb File.read './views/work.erb'
  set_cache(html)
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
  html = erb File.read './views/blog';
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
    @contents.body = RDiscount.new(@contents.body).to_html
  end
  n=200
  @twitter_description = Sanitize.clean(@contents.body.split(/\s+/, n+1)[0...n].join(' '))
  html = erb File.read './views/blog_post.erb'
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
  html = erb File.read './views/blog.erb'
  set_cache(html)
end

get '/archive' do
  html = is_cached
  if html
    return html
  end
  results = archive
  @title = "Archive"
  @description = "An archive of Millwood Online Blog posts."
  html = erb results
  set_cache(html)
end

get '/archive/:date/?:page?/?' do
  halt 404 if params[:date] and (!params[:date].match(/\A[0-9]+\Z/) or params[:date].length != 6)
  halt 404 if params[:page] and !params[:page].match(/\A[0-9]+\Z/)
  html = is_cached
  if html
    return html
  end
  date = params[:date].scan(/.{1,4}/).map {|id| id.to_i }
  page = 1
  from = "#{date[0]}-#{date[1]}-01"
  to = (date[1] == 12) ? "#{date[0]+1}-01-01" : "#{date[0]}-#{date[1]+1}-01"
  if params[:page]
    page = params[:page].to_i
    offset = 5*page-5
    @contents = Content.all(:fields => [:title, :body, :alias, :created, :markdown], :conditions => [ 'created >= ? and created < ?', from, to], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5, :offset => offset)  
  else
    @contents = Content.all(:fields => [:title, :body, :alias, :created, :markdown], :conditions => [ 'created >= ? and created < ?', from, to], :type => 'blog', :published => true, :order => [ :created.desc ], :limit => 5)
  end
  halt 404 if @contents.empty?

  size = @contents.size
  pager_prev = "<li class='previous'><a href='/archive/#{params[:date]}/#{page-1}'>&larr; Newer</a></li>" if page > 1
  pager_next = "<li class='next'><a href='/archive/#{params[:date]}/#{page+1}'>Older &rarr;</a></li>" if size == 5
  @pager = "<ul class='pager'>#{pager_prev}#{pager_next}</ul>"
  @title = "Archive - #{Date::MONTHNAMES[date[1]]} #{date[0]}"
  @description = "Archive of blog posts from #{Date::MONTHNAMES[date[1]]} #{date[0]} featuring topics such as Drupal, Ruby-on-Rails, Sinatra and web development."
  html = erb File.read './views/blog.erb'
  set_cache(html)
end

get '/contact/?' do
  @title = 'Contact'
  @description = "Call 01873 878587 or email Tim Millwood."
  erb File.read './views/contact.erb'
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
  
  redirect '/contact'
end

get '/php-drupal-web-developer-cardiff-abergavenny-wales-uk' do
  @head_title = "Drupal Web Design and Development | Cardiff / Abergavenny, Wales, UK"
  @description = "With over 5 years of Drupal development experience, working in Cardiff / Abergavenny, Wales, UK for international clients."
  erb File.read './views/drupal.erb'
end

get '/ruby-on-rails-sinatra-web-developer-cardiff-abergavenny-wales-uk' do
  @head_title = "Ruby on Rails / Sinatra Web Design and Development | Cardiff / Abergavenny, Wales, UK"
  @description = "We're looking to take on Ruby-on-Rails and Sinatra web development projects, working from Cardiff / Abergavenny, Wales, UK."
  erb File.read './views/ruby.erb'
end

get '/rip-drippic' do
  @title = "R.I.P Drippic"
  @description = "Drippic has closed."
  erb '<p>Sorry, Drippic has closed.</p><p>The code is still available on <a href="http://drupal.org/project/drippic">Drupal.org</a> if you really want it.</p>'
end