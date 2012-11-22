before do
  if ['drippic.com', 'www.drippic.com'].include? request.host
    redirect "http://www.millwoodonline.co.uk/rip-drippic", 301
  end

  content_type 'text/html; charset=utf8'
  if !logged_in?
   expires 3600, :public, :must_revalidate
  else
    cache_control :no_cache
  end

  @args = request.path.split('/').map {|x| x=="" ? "/" : x}
  @block = erb :block, :layout => false
end
