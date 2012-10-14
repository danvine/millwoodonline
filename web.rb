require 'rubygems'
require 'sinatra'
require 'haml'
require "dm-core"
require "dm-migrations"
require "digest/sha1"
require 'rack-flash'
require "sinatra-authentication"
DataMapper.setup(:default, "mysql://webuser:secret@localhost/stampclub")
DataMapper.auto_upgrade!
use Rack::Session::Cookie, :secret => 'superdupersecret'
use Rack::Flash
