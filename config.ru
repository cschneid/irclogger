$:.unshift './vendor/sinatra/lib'
require 'sinatra'

Sinatra::Application.default_options.merge!(
  :run => false,
  :env => :production
)

log = File.open("app.log", "a+")
STDERR.reopen log
STDOUT.reopen log

require 'irclogger'
run Sinatra.application 
