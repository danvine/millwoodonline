before do
  if ['www.millwoodonline.com', 'millwoodonline.com', 'millwoodonline.co.uk'].include? request.host
    redirect "http://www.millwoodonline.co.uk" + request.path, 301
  end

  content_type 'text/html; charset=utf8'
  expires 300, :public
 
  if request.post?
   if session[:csrf] != params[:csrf]
     halt 503, erb('<h1>500: oops</h1><p>Form Error<br/> s: ' + session[:csrf] + ' p: ' + params[:csrf] + '</p>')
   end
  end 
  
  time = Time.now.to_s
  @key = Digest::SHA1.hexdigest(time)
  session[:csrf] = @key
  
  blockload
end
