get '/tag/:tag/rss.xml' do
  content_type 'text/xml; charset=utf8'
  page = is_cached
  if page
    return page
  end
  tag = Sanitize.clean(params[:tag].gsub('-', ' '))
  tag_id = Tag.first(:tag => tag)
  if !tag_id
    halt 404
  end
  @contents = Content.all(:type => 'blog', :published => true, :content_tags => {:tag_id => tag_id.id}, :order => [ :created.desc ], :limit => 10)

  if @contents.size == 0
    halt 404
  end
  
  @title = "#{Sanitize.clean(params[:tag]).gsub('-', ' ').capitalize}"
  @description = "Blog posts relating to #{Sanitize.clean(params[:tag]).gsub('-', ' ').capitalize}."
  page = builder :rss
  set_cache(page)
end

get '/blog/rss.xml' do
  content_type 'text/xml; charset=utf8'
  page = is_cached
  if page
    return page
  end
  
  @contents = Content.all(:fields => [:title, :body, :created, :alias], :type => 'blog', :published => true, :limit => 10, :order => [ :created.desc ])
  page = builder :rss
  set_cache(page)
end

get '/sitemap.xml' do
  content_type 'text/xml; charset=utf8'
  page = is_cached
  if page
    return page
  end

  @contents = Content.all(:fields => [:alias, :created], :type => 'blog', :published => true, :order => [ :created.desc ])
  @tags = Tag.all(:fields => [:tag])

  page = builder :sitemap
  set_cache(page)
end
