$:.unshift File.dirname(__FILE__) + '/yail/lib'
$:.unshift File.dirname(__FILE__) + '/../lib'

require 'net/yail/IRCBot'
require 'date'
require 'models'

# Generic interface to the Message table, inserts a single line
def log(channel, nick, text)
  Message.create(:channel => channel, :nick => nick, :timestamp => Time.now, :line => text)
end

# These methods are the actul event handlers.  They just build the text string, and hand off to log()
#
# Docs copied from yail:
#   * actor: Nickname of originator of an action
#   * target: Nickname for private actions, channel name for public
#   * text: Actual message/emote/notice/etc
#   * args: For numeric handlers, this is a hash of :fullactor, :actor, and
#     :target.  Most numeric handlers I've built don't need this, so I made it easier to just get what you specifically want.


# This gets fired when we're done joining
def handle_welcome(text, args)
  hup
  false # true stops the event chain
end

#PRIVMSG #cschneid-test ACTION ME MESSAGE 2
# A generic message
def handle_msg(fullactor, actor, target, text)
  log(target, actor, "#{text}")
  false
end

# A notice happened... what's a notice on IRC?
def handle_notice(fullactor, actor, target, text)
  log(target, actor, "#{text}")
  false
end

# Somebody got their mode changed
def handle_mode(fullactor, actor, target, modes, objects)
  return false # DONT LOG RIGHT NOW
  log("")
  false
end

# Somebody joined
def handle_join(fullactor, actor, target)
  log(target, nil, "#{actor} joined #{target}")
  false
end

# Somebody left the channel
def handle_part(fullactor, actor, target, text)
  log(target, nil, "#{actor} left #{target} (#{text})")
  false
end

# Somebody got kicked
def handle_kick(fullactor, actor, target, object, text)
  log(target, nil, "#{actor} was kicked from #{target} (#{text})")
  false
end

# Somebody quit
def handle_quit(fullactor, actor, text)
  return false # Don't handle quit messages right now
  log("")
  false
end

# Nick change
def handle_nick(fullactor, actor, nickname)
  return false # dont' handle right now... TODO: Figure a way to handle this.
  log("")
  false
end


def hup
  channels = Channel.get_channels
  channels.each {|c| @irc.join c }
end

@irc = Net::YAIL.new(
  :address    => 'irc.freenode.org',
  :username   => 'irclogger.com',
  :realname   => 'irclogger.com',
  :nicknames  => ['irclogger-com', 'ircloggercom', 'irclogger-com_', 'ircloggercom__']
)

@irc.prepend_handler :incoming_welcome , method(:handle_welcome)
@irc.prepend_handler :incoming_msg     , method(:handle_msg)
@irc.prepend_handler :incoming_notice  , method(:handle_notice)
@irc.prepend_handler :incoming_mode    , method(:handle_mode)
@irc.prepend_handler :incoming_join    , method(:handle_join)
@irc.prepend_handler :incoming_part    , method(:handle_part)
@irc.prepend_handler :incoming_kick    , method(:handle_kick)
@irc.prepend_handler :incoming_quit    , method(:handle_quit)
@irc.prepend_handler :incoming_nick    , method(:handle_nick)

trap :HUP do 
  hup
end

@irc.start_listening
while @irc.dead_socket == false
  # Avoid major CPU overuse by taking a very short nap
  sleep 0.05
end

