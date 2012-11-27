require './web.rb'

use Rack::CanonicalHost, ENV['HOST'], ignore: ['drippic.com','www.drippic.com','localhost']
use Rack::Session::Pool, :secret => ENV['SECRET'], :key => 'millwoodonline'
use Rack::Flash
use Rack::Csrf

run Sinatra::Application
