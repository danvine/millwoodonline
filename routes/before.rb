before do
  if ['www.millwoodonline.com', 'millwoodonline.com', 'millwoodonline.co.uk'].include? request.host
    redirect "http://www.millwoodonline.co.uk" + request.path, 301
  end

  content_type 'text/html; charset=utf8'
  expires 300, :public
   
  blockload
end
