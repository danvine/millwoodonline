get '/node/:nid/?' do
  nid = Sanitize.clean(params[:nid])
  result = REDIS.get("redirect:node/#{nid}")
  if result
    response.header['redis'] = 'HIT'
    redirect result, 301
  end

  contents = Content.first(:fields => [:alias], :type => 'blog', :published => true, :id => nid)
  response.header['redis'] = 'MISS'

  if contents.nil?
    result = '/'
    REDIS.setex("redirect:node/#{nid}", 31536000,result)
    redirect result
  end

  result = '/blog/' + contents.alias
  REDIS.setex("redirect:node/#{nid}", 31536000,result)
  redirect result, 301
end

get '/tags/*' do
  redirect '/tag/' + params[:splat].first, 301
end

get '/tags/?' do
  redirect '/tag', 301
end

get '/taxonomy/term/25/0/feed/?' do
  redirect '/tag/drupal/rss.xml', 301
end

get '/taxonomy/term/25/?' do
  redirect '/tag/drupal', 301
end

get '/taxonomy/?*?' do
  redirect '/tag', 301
end

get '/photos/?*?' do
  redirect '/rip-drippic', 301
end

get '/rss.xml' do
  redirect '/blog/rss.xml', 301
end

get '/:alias/?' do
  url_alias = Sanitize.clean(params[:alias])
  result = REDIS.get("redirect:#{url_alias}")
  if result == "404"
    response.header['redis'] = 'HIT'
    halt 404
  elsif result
    response.header['redis'] = 'HIT'
    redirect result, 301
  end
  contents = Content.first(:fields => [:alias], :type => 'blog', :published => true, :alias => url_alias)
  response.header['redis'] = 'MISS'

  if contents.nil?
    REDIS.setex("redirect:#{url_alias}", 31536000, "404")
    halt 404
  end
  REDIS.setex("redirect:#{url_alias}", 31536000, "/blog/#{contents.alias}")
  redirect '/blog/' + contents.alias, 301
end