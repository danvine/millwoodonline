before do
  if ['drippic.com', 'www.drippic.com'].include? request.host
    redirect "http://www.millwoodonline.co.uk/rip-drippic", 301
  end

  content_type 'text/html; charset=utf8'
  @description = "The digital home of Tim Millwood, a PHP / Drupal & Ruby-on-Rails / Sinatra Web Developer based in Cardiff / Abergavenny, Wales, UK"
  @block = erb(File.read('./views/block.erb'), :layout => false) if arg(0) != 'admin'
end