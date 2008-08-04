require 'rubygems'
require 'net/yail'

# My abstraction from adapter to a real bot.
class IRCBot
  attr_reader :irc

  public

  # Creates a new bot yay.  Note that due to my laziness, the options here
  # are almost exactly the same as those in Net::YAIL.  But at least there
  # are more defaults here.
  #
  # Options:
  # * <tt>:irc_network</tt>: Name/IP of the IRC server
  # * <tt>:channels</tt>: Channels to automatically join on connect
  # * <tt>:port</tt>: Port number, defaults to 6667
  # * <tt>:username</tt>: Username reported to server
  # * <tt>:realname</tt>: Real name reported to server
  # * <tt>:nicknames</tt>: Array of nicknames to cycle through
  # * <tt>:silent</tt>: Silence a lot of reports
  # * <tt>:loud</tt>: Lots more verbose reports
  def initialize(options = {})
    @start_time = Time.now

    @channels = options[:channels] || []
    @irc_network = options[:irc_network]
    @port = options[:port] || 6667
    @username = options[:username] || 'IRCBot'
    @realname = options[:realname] || 'IRCBot'
    @nicknames = options[:nicknames] || ['IRCBot1', 'IRCBot2', 'IRCBot3']
    @silent = options[:silent] || false
    @loud = options[:loud] || false
  end

  # Returns a string representing uptime
  def get_uptime_string
    uptime = (Time.now - @start_time).to_i
    seconds = uptime % 60
    minutes = (uptime / 60) % 60
    hours = (uptime / 3600) % 24
    days = (uptime / 86400)

    str = []
    str.push("#{days} day(s)") if days > 0
    str.push("#{hours} hour(s)") if hours > 0
    str.push("#{minutes} minute(s)") if minutes > 0
    str.push("#{seconds} second(s)") if seconds > 0

    return str.join(', ')
  end

  # Creates the socket connection and registers the (very simple) default
  # welcome handler.  Subclasses should build their hooks in
  # add_custom_handlers to allow auto-creation in case of a restart.
  def connect_socket
    @irc = Net::YAIL.new(
      :address    => @irc_network,
      :port       => @port,
      :username   => @username,
      :realname   => @realname,
      :nicknames  => @nicknames,
      :silent     => @silent,
      :loud       => @loud
    )

    # Simple hook for welcome to allow auto-joining of the channel
    @irc.prepend_handler :incoming_welcome, self.method(:welcome)

    add_custom_handlers
  end

  # To be subclassed - this method is a nice central location to allow the
  # bot to register its handlers before this class takes control and hits
  # the IRC network.
  def add_custom_handlers
    raise "You must define your handlers in add_custom_handlers, or else " +
        "explicitly override with an empty method."
  end

  # Enters the socket's listening loop(s)
  def start_listening
    # If socket's already dead (probably couldn't connect to server), don't
    # try to listen!
    if @irc.dead_socket
      $stderr.puts "Dead socket, can't start listening!"
    end

    @irc.start_listening
  end

  # Tells us the main app wants to just wait until we're done with all
  # thread processing, or get a kill signal, or whatever.  For now this is
  # basically an endless loop that lets the threads do their thing until
  # the socket dies.  If a bot wants, it can handle :irc_loop to do regular
  # processing.
  def irc_loop
    while true
      until @irc.dead_socket
        sleep 15
        @irc.handle(:irc_loop)
        Thread.pass
      end

      # Disconnected?  Wait a little while and start up again.
      sleep 30
      @irc.stop_listening
      self.connect_socket
      start_listening
    end
  end

  private
  # Basic handler for joining our channels upon successful registration
  def welcome(text, args)
    @channels.each {|channel| @irc.join(channel) }
    # Let the default welcome stuff still happen
    return false
  end

  ################
  # Helpful wrappers
  ################

  # Wraps Net::YAIL.me
  def bot_name
    @irc.me
  end

  # Wraps Net::YAIL.msg
  def msg(*args)
    @irc.msg(*args)
  end

  # Wraps Net::YAIL.act
  def act(*args)
    @irc.act(*args)
  end

  # Wraps Net::YAIL.join
  def join(*args)
    @irc.join(*args)
  end

  # Wraps Net::YAIL.report
  def report(*args)
    @irc.report(*args)
  end

  # Wraps Net::YAIL.nick
  def nick(*args)
    @irc.nick(*args)
  end
end
