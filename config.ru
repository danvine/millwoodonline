require './web.rb'
use Rack::CanonicalHost, 'www.millwoodonline.co.uk'
run Sinatra::Application
