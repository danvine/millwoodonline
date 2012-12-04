helpers do
  
  def enforce_admin
    if !current_user.admin?
      halt 403
    end
  end

  def upload(filename, file)
    AWS::S3::Base.establish_connection!(
      :access_key_id     => ENV['ACCESS_KEY_ID'],
      :secret_access_key => ENV['SECRET_ACCESS_KEY']
    )
    AWS::S3::S3Object.store(
      'images/' + filename,
      open(file.path),
      'millwoodonline'
    )
    return filename
  end

  def archive
    results = REDIS.get("archive:results")
    if results
      return results
    end
    archive = repository(:default).adapter.select("select to_char(created, 'YYYY MM') as created_year_month, count(id) as num from contents where published = TRUE and type = 'blog' group by created_year_month order by created_year_month desc")
    results = "<ul>"
    archive.each do |month|
      month_split = month[:created_year_month].split(' ')
      results = "#{results} <li><a href='/archive/#{month_split[0]}#{month_split[1]}'>#{Date::MONTHNAMES[month_split[1].to_i]} #{month_split[0]}</a> (#{month[:num].to_s})</li>"
    end
    results = "#{results}</ul>"
    REDIS.setex("archive:results",10800,results)
    return results
  end

  def tweets
    results = REDIS.get("twitter:timeline")
    if results
      return results
    end
    results = "<ul class='media-list' id='tweets'>"
    Twitter.user_timeline("timmillwood", {:exclude_replies => true, :include_rts => false})[0..2].each do |tweet|      
      results = "#{results} <li class='media well well-small'><img src='#{tweet[:user][:profile_image_url]}' class='pull-left media-object' alt='Tim Millwood - Twitter'><div class='media-body'><span class='label label-info'>Tweeted:</span> #{auto_link(tweet[:text])}<br><small><a href='https://twitter.com/timmillwood/status/#{tweet[:id].to_s}'>#{tweet[:created_at].strftime("%d %b %Y - %l:%M%P")}</a></small></div></li>"
    end
    results = "#{results}</ul>"
    REDIS.setex("twitter:timeline",300,results)
    return results
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
  
  def is_cached
    tag = "url:#{request.url}"
    page = REDIS.get(tag)
    if page and !logged_in?
      expires 3600, :public, :must_revalidate
      etag Digest::SHA1.hexdigest(page)
      ttl = 3600 - REDIS.ttl(tag)
      response.header['Age'] = ttl.to_s
      response.header['X-redis'] = 'HIT'
      return page
    end
  end
  
  def set_cache(page)
    if page and !logged_in?
      expires 3600, :public, :must_revalidate
      etag Digest::SHA1.hexdigest(page)
      tag = "url:#{request.url}"
      REDIS.setex(tag, 3600, page)
    else
      cache_control :no_cache
    end
    response.header['X-redis'] = 'MISS'
    return page
  end
end
