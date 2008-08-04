#!/usr/bin/env ruby

require 'rubygems'
require 'logger_bot'
require 'getopt/long'

# This code just launches our logger with certain parameters.
#
# If options are specified, they override the default yaml file.  If a
# different yaml file is specified, its settings are read, then overridden
# by options.
#
# Passwords hash cannot be specified on the command-line - yaml or nothing.

opt = Getopt::Long.getopts(
  ['--silent',      '-s', Getopt::BOOLEAN],
  ['--loud',        '-l', Getopt::BOOLEAN],
  ['--network',     '-n', Getopt::OPTIONAL],
  ['--output-dir',  '-o', Getopt::OPTIONAL],
  ['--master',      '-m', Getopt::OPTIONAL],
  ['--yaml',        '-y', Getopt::OPTIONAL]
)

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
  :silent       => options['silent'],
  :loud         => options['loud'],
  :irc_network  => options['network'],
  :output_dir   => options['output-dir'],
  :master       => options['master'],
  :passwords    => options['passwords']
)
@bot.irc_loop
