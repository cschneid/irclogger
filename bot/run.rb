#!/usr/bin/env ruby

require 'rubygems'
require 'logger_bot'


opt['yaml'] ||= File.dirname(__FILE__) + '/default.yml'
if File.exists?(opt['yaml'])
  options = File.open(opt['yaml']) {|f| YAML::load(f)}
else
  options = {}
end

for key in %w{silent loud network output-dir master}
  options[key] ||= opt[key]
end

@bot = LoggerBot.new(
  :irc_network  => options['network'],
  :master       => options['master'],
  :passwords    => options['passwords']
  :nicknames = ['irclogger-com', 'ircloggercom', 'irclogger-com_', 'ircloggercom__']
)

trap :USR_2 do 
  # Do crap here
end


@bot.irc_loop
