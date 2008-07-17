$:.unshift File.join(File.dirname(__FILE__), '/vendor/sinatra/lib/')
require 'sinatra'

## DB ###########################
require 'sequel'
Sequel.connect 'mysql://root@localhost/irclogs'
class Message < Sequel::Model(:irclog)
  def message_type
    return "msg" if msg?
    return "info" if info?
    ""
  end

  def msg?
    ! nick.blank?
  end

  def info?
    ! msg?
  end
end


helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

## Web ##########################
get '/' do
  @messages = Message.order(:timestamp)
  erb :log
end

## Monkey Patching #############
class Fixnum 
  def minutes
    self * 60
  end
end
