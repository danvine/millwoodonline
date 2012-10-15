require 'rubygems'
require 'sinatra'
require 'haml'
require "dm-core"
require "dm-migrations"
require "digest/sha1"
require 'rack-flash'
require "sinatra-authentication"
DataMapper.setup(:default, 'postgres://lbhhmtafaowdgx:tpjR5sVtWEswPaJ9tsQ7q-_cdj@ec2-54-243-233-216.compute-1.amazonaws.com:5432/d9r9mjl2refokn')
DataMapper.auto_upgrade!
use Rack::Session::Cookie, :secret => 'superdupersecret'
use Rack::Flash

get '/' do
  current_user.to_json
end
