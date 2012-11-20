before do
  if ['www.millwoodonline.com', 'millwoodonline.com', 'millwoodonline.co.uk'].include? request.host
    redirect "http://www.millwoodonline.co.uk" + request.path, 301
  end

  if ['drippic.com', 'www.drippic.com'].include? request.host
    redirect "http://www.millwoodonline.co.uk/rip-drippic", 301
  end

  content_type 'text/html; charset=utf8'
  expires 300, :public
   
  @args = request.path.split('/').map {|x| x=="" ? "/" : x}
  @block = erb :block, :layout => false
end
