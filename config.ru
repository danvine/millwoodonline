require './web.rb'

use Rack::CanonicalHost, 'www.millwoodonline.co.uk', ignore: ['drippic.com','www.drippic.com','localhost']

use Rack::Session::Cookie, :secret => ENV['SECRET']
use Rack::Flash
use Rack::Csrf, :raise => true

run Sinatra::Application
