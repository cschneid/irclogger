require 'rake/clean'

task :default => :test

desc 'Run tests'
task :test do
  sh "testrb test/*_test.rb"
end

desc 'Start a development server'
task :start do
  command = "thin -s 2 -C config.yml -R config.ru start"
  STDERR.puts(command) if verbose
  exec(command)
end

desc 'Stop a development server'
task :stop do
  command = "thin -s 2 -C config.yml -R config.ru stop"
  STDERR.puts(command) if verbose
  exec(command)
end

desc 'Starts mysql with the database'
task :mysql do
  command = "mysql -uroot irclogs"
  STDERR.puts(command) if verbose
  exec(command)
end

# Environment Configuration ==================================================

def wink_environment
  if ENV['WTE_ENV']
    ENV['WTE_ENV'].to_sym
  elsif defined?(Sinatra)
    Sinatra.application.options.env
  else
    :development
  end
end

task :environment do
  $:.unshift 'sinatra/lib' if File.exist?('sinatra')
  $:.unshift 'lib'
  $:.unshift '.'
  require 'whattoeat'
end




