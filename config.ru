require './web.rb'

use Rack::CanonicalHost, ENV['HOST'], ignore: ['drippic.com','www.drippic.com','localhost']
use Rack::Session::Cookie, :secret => ENV['SECRET'], :key => 'millwoodonline', :domain => ENV['HOST']
use Rack::Flash
use Rack::Csrf, :raise => true

run Sinatra::Application
