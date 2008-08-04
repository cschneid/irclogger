#!/usr/bin/ruby

require 'rubygems'
require 'net/yail/IRCBot'
require 'date'

class LoggerBot < IRCBot
  BOTNAME = 'Logger'
  BOTVERSION = 'v0.1.0'

  public
  # Starts a new instance
  #
  # Options:
  # * <tt>:irc_network</tt>: IP/name of server
  # * <tt>:port</tt>: ...
  # * <tt>:loud</tt>: Overly-verbose logging
  # * <tt>:silent</tt>: Very little logging
  # * <tt>:master</tt>: User who can order quits
  # * <tt>:output_dir</tt>: Where to store log files
  # * <tt>:passwords</tt>: Hash of channel=>pass for joining channels
  def initialize(options = {})
    @master       = options.delete(:master)
    @output_dir   = options.delete(:output_dir) || File.dirname(__FILE__)

    # Log files per channel - logs rotate every so often, so we have to store
    # filenames on a per-channel basis
    @current_log  = {}
    @log_date     = {}
    @passwords    = options[:passwords] || {}

    options[:username] = BOTNAME
    options[:realname] = BOTNAME
    options[:nicknames] = ['LoggerBot', 'Logger_Bot', 'logger_bot', '_LoggerBot', 'LoggerBot_']

    # Set up IRCBot, our loving parent, and begin
    super(options)
    self.connect_socket
    self.start_listening
  end

  # Add hooks on startup (base class's start method calls add_custom_handlers)
  def add_custom_handlers
    # Set up hooks
    @irc.prepend_handler(:incoming_msg,             self.method(:_in_msg))
    @irc.prepend_handler(:incoming_act,             self.method(:_in_act))
    @irc.prepend_handler(:incoming_invite,          self.method(:_in_invited))
    @irc.prepend_handler(:incoming_kick,            self.method(:_in_kick))

    @irc.prepend_handler(:outgoing_join,            self.method(:_out_join))
  end

  private
  # Incoming message handler
  def _in_msg(fullactor, user, channel, text)
    # check if this is a /msg command, or normal channel talk
    if channel =~ /#{bot_name}/
      incoming_private_message(user, text)
    else
      incoming_channel_message(user, channel, text)
    end
  end

  def _in_act(fullactor, user, channel, text)
    # check if this is a /msg command, or normal channel talk
    return if (channel =~ /#{bot_name}/)
    log_channel_message(user, channel, "#{user} #{text}")
  end

  # TODO: recalls the most recent logs for a given channel by reading from
  # the file system or using a hash of log data.  Or both.
  def recent_logs(channel, num = 10)
    raise "Not implemented"
  end

  # TODO: Searches logs for a given pattern.  Relies on the file system data
  # to do a comprehensive search, and 'grep', so SANITIZE INPUT!
  def search_logs(pattern)
    raise "Not implemented"
  end

  # Gives the user very simplistic information.  TODO: Add a command for
  # accessing and searching logs.
  def incoming_private_message(user, text)
    case text
      when /\bhelp\b/i
        msg(user, 'LoggerBot at your service - I log all messages and actions in any channel')
        msg(user, 'I\'m in.  In the future I\'ll offer searchable logs.  If you /INVITE me to')
        msg(user, 'a channel, I\'ll pop in and start logging.')
        return
    end

    msg(user, "I don't log private messages.  If you'd like to know what I do, ")
    msg(user, "enter \"HELP\"")
  end

  def incoming_channel_message(user, channel, text)
    # check for special stuff before keywords
    # Nerdmaster is allowed to do special ordering
    if @master == user
      if (text == "#{bot_name}: QUIT")
        self.irc.quit("Ordered by my master")
        sleep 1
        exit
      end
    end

    case text
      when /^\s*#{bot_name}(:|)\s*uptime\s*$/i
        msg(channel, get_uptime_string)

      when /botcheck/i
        msg(channel, "#{BOTNAME} #{BOTVERSION}")

      else
        log_channel_message(user, channel, "<#{user}> #{text}")
    end
  end

  # Logs the message data to a flat text file.  Fun.
  def log_channel_message(user, channel, text)
    today = Date.today
    if @current_log[channel].nil? || @log_date[channel] != today
      chan_dir = @output_dir + '/' + channel
      Dir::mkdir(chan_dir) unless File.exists?(chan_dir)
      filename = chan_dir + '/' + today.strftime('%Y%m%d') + '.log'
      @current_log[channel] = filename
      @log_date[channel] = today
    end

    time = Time.now.strftime '%H:%M:%S'
    File.open(@current_log[channel], 'a') do |f|
      f.puts "[#{time}] #{text}"
    end
  end

  # Invited to a channel for logging purposes - simply auto-join for now.
  # Maybe allow only @master one day, or array of authorized users.
  def _in_invited(fullactor, actor, target)
    join target
  end

  # If bot is kicked, he must rejoin!
  def _in_kick(fullactor, actor, target, object, text)
    if object == bot_name
      # Rejoin almost immediately - logging is important.
      join target
    end

    return true
  end

  # We're trying to join a channel - use key if we have one
  def _out_join(target, pass)
    key = @passwords[target]
    pass.replace(key) unless key.to_s.empty?
  end
end
