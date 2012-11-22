before do
  if ['drippic.com', 'www.drippic.com'].include? request.host
    redirect "http://www.millwoodonline.co.uk/rip-drippic", 301
  end

  content_type 'text/html; charset=utf8'
  expires 3600, :public
   
  @args = request.path.split('/').map {|x| x=="" ? "/" : x}
  @block = erb :block, :layout => false
end
