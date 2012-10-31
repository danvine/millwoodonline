helpers do
  def blockload
    @block = erb :block, :layout => false
  end
  
  def enforce_admin
    if !current_user.admin?
      halt 403
    end
  end
  
  def cache(tag,ttl,use_cache,block)
    page = REDIS.get(tag)
    if page and use_cache and !logged_in?
      ttl = REDIS.ttl(tag)
      response.header['redis-ttl'] = ttl.to_s
      response.header['redis'] = 'HIT'
      return page
    else
      page = block.call
      REDIS.setex(tag,ttl,page) if use_cache and !logged_in?
      response.header['redis'] = 'MISS'
      return page 
    end
  end

  def cache_url(ttl=300,use_cache=true,&block)
    cache("url:#{request.url}",ttl,use_cache,block)
  end
end
