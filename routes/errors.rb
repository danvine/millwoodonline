not_found do
  erb "<h1>404: Page not found</h1>"
end

error 500 do
  erb "<h1>500: oops</h1>" + env['sinatra.error'].message
end

error 403 do
  erb "<h1>403: Access denied</h1>"
end
