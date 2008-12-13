require 'rake/clean'

task :default => :test

desc 'Run tests'
task :test do
  sh "testrb test/*_test.rb"
end

desc 'Start a development server'
task :start do
  command = "thin -s 1 -C config.yml -R config.ru start"
  STDERR.puts(command) if verbose
  exec(command)
end

desc 'Stop a development server'
task :stop do
  command = "thin -s 1 -C config.yml -R config.ru stop"
  STDERR.puts(command) if verbose
  exec(command)
end

desc 'Restarts the server'
task :restart => [:stop, :start]

desc 'Starts mysql with the database'
task :mysql do
  command = "mysql -uroot irclogs"
  STDERR.puts(command) if verbose
  exec(command)
end

