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