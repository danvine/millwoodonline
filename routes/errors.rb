not_found do
  @title = "404"
  @description = "Error: 404 - Millwood Online"
  erb "<h2>Page not found</h2>"
end

error 500 do
  @title = "500"
  @description = "Error: 500 - Millwood Online"
  erb "<h2>oops</h2>" + env['sinatra.error'].message
end

error 403 do
  @title = "403"
  @description = "Error: 503 - Millwood Online"
  erb "<h2>Access denied</h2>"
end
