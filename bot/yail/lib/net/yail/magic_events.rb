module Net
module IRCEvents

# This module contains all the "magic" methods that need to happen regardless
# of user-defined event hooks and such.
module Magic
  private

  # Sets up the magic handlers that must happen no matter what else occurs
  def setup_magic_handlers
    prepend_handler :incoming_welcome,          self.method(:magic_welcome)
    prepend_handler :incoming_ping,             self.method(:magic_ping)
    prepend_handler :incoming_nick,             self.method(:magic_nick)
  end

  # We were welcomed, so we need to set up initial nickname and set that we
  # registered so nick change failure doesn't cause DEATH!
  def magic_welcome(text, args)
    report "#{args[:fullactor]} welcome message: #{text}"
    if (text =~ /(\S+)!\S+$/)
      @me = $1
    elsif (text =~ /(\S+)$/)
      @me = $1
    end

    @registered = true
    mode @me, 'i'

    # Don't break the chain if user wants their own handler
    return false
  end

  # Ping must have a PONG even if user wants their own handler
  def magic_ping(text)
    @socket.puts "PONG :#{text}"

    # Don't break the chain, man
    return false
  end

  # If bot changes his name, @me must change
  def magic_nick(fullactor, actor, nickname)
    # Reset name if it's me
    if actor.downcase == @me.downcase
      @me = nickname
    end

    # Allow user-defined events (and/or reporting)
    return false
  end

end

end
end
