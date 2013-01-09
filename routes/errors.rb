not_found do
  @title = "404 Page not found"
  @description = "Error: 404 - Millwood Online"
  videos = ["l4hv_8TXFWg", "GUpXUP12fG8", "Cl45v957kJg", "xhZcAVSp1n4", "kntzQiaFzOQ", "h97iqixI45o", "A7zoudZMxVE"]
  erb "<h2>Enjoy this Eric Clapton video instead:</h2><div style='position:relative;padding-bottom:56.25%;padding-top:30px;height:0;overflow:hidden;'><iframe src='https://www.youtube-nocookie.com/embed/#{videos.sample}?rel=0&autoplay=1&iv_load_policy=3&loop=1&showinfo=0&modestbranding=1&controls=0' frameborder='0' allowfullscreen style='position:absolute;top:0;left:0;width:100%;height:100%;'></iframe></div>"
end

error 500 do
  @title = "500"
  @description = "Error: 500 - Millwood Online"
  erb "<h2>oops</h2>" + env['sinatra.error'].message
end

error 403 do
  @title = "403"
  @description = "Error: 403 - Millwood Online"
  erb "<h2>Access denied</h2>"
end
