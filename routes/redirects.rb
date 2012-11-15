get '/node/:nid/?' do
  nid = Sanitize.clean(params[:nid])
  contents = Content.first(:fields => [:alias], :type => 'blog', :published => true, :id => nid)
  if contents.nil?
    halt 404
  end
  redirect '/blog/' + contents.alias, 301
end

get '/tags/*' do
  redirect '/tag/' + params[:splat].first, 301
end

get '/taxonomy/term/25/0/feed/?' do
  redirect '/tag/drupal/rss.xml', 301
end

get '/taxonomy/term/25/?' do
  redirect '/tag/drupal', 301
end

get '/rss.xml' do
  redirect '/blog/rss.xml', 301
end

get '/:alias/?' do
  url_alias = Sanitize.clean(params[:alias])
  contents = Content.first(:fields => [:alias], :type => 'blog', :published => true, :alias => url_alias)
  if contents.nil?
    halt 404
  end
  redirect '/blog/' + contents.alias, 301
end