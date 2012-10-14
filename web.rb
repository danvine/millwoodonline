require 'rubygems'
require 'sinatra'
require 'haml'
require "dm-core"
require "dm-migrations"
require "digest/sha1"
require 'rack-flash'
require "sinatra-authentication"
DataMapper.setup(:default, 'sqlite::memory:')
DataMapper.auto_upgrade!
use Rack::Session::Cookie, :secret => 'superdupersecret'
use Rack::Flash
