module Net

# All output APIs live here.  In most cases, an outgoing handler will get a
# call, but will not be able to stop the socket output since that's sorta
# an essential part of this whole library.
#
# ==Argument Duping
#
# Output APIs dup incoming args before sending them off to handlers.  This
# is a mechanism that I think could be done better, but I can't figure a good
# way to do it at the moment.  The reason this is necessary is for a specific
# situation where a bot has an array of response messages, and needs to filter
# those messages.  A call to "msg(messages[rand(10)])" with a handler on :outgoing_msg
# that does something like <code>text.gsub!('a', '@')</code> (like a leetspeek
# filter) shouldn't destroy the original data in the messages array.
#
# This could be left up to the programmer, but it seems like something that
# a library should own - protecting the programmer for having to remember that
# sort of crap, especially if the app is calling msg, act, ctcp, etc. in
# various ways from multiple points in the code....
#
# ==Apologies, good sirs
# 
# If a method exists in this module, and it isn't the +raw+ method, chances
# are it's got a handler in the form of :outgoing_<method name>.  I am hoping
# I document all of those in the main Net::YAIL code, but if I miss one, I
# apologize.
module IRCOutputAPI
  # Spits a raw string out to the server - in case a subclass wants to do
  # something special on *all* output, please make all output go through this
  # method.  Don't use puts manually.  I will kill violaters.  Legally
  # speaking, that is.
  def raw(line, report = true)
    @socket.puts line
    report "bot: '#{line}'" if report
  end

  # Calls :outgoing_privmsg handler, then sends a message (text) out to the
  # given channel/user (target), and reports itself with the given string.
  # This method shouldn't be called directly most of the time - just use msg,
  # act, ctcp, etc.
  #
  # This is sort of the central message output - everything that's based on
  # PRIVMSG (messages, actions, other ctcp) uses this.  Because these messages
  # aren't insanely important, we actually buffer them instead of sending
  # straight out to the channel.  The output thread has to deal with
  # sending these out.
  def privmsg(target, text, report_string)
    # Dup strings so handler can filter safely
    target = target.dup
    text = text.dup

    handle(:outgoing_privmsg, target, text)

    @privmsg_buffer_mutex.synchronize do
      @privmsg_buffer[target] ||= Array.new
      @privmsg_buffer[target].push([text, report_string])
    end
  end

  # Calls :outgoing_msg handler, then privmsg to send the message out.  Could
  # be used to send any privmsg, but you're betting off using act and ctcp
  # shortcut methods for those types.  Target is a channel or username, text
  # is the message.
  def msg(target, text)
    # Dup strings so handler can filter safely
    target = target.dup
    text = text.dup

    handle(:outgoing_msg, target, text)

    report_string = @silent ? '' : "{#{target}} <#{@me}> #{text}"
    privmsg(target, text, report_string)
  end

  # Calls :outgoing_ctcp handler, then sends CTCP to target channel or user
  def ctcp(target, text)
    # Dup strings so handler can filter safely
    target = target.dup
    text = text.dup

    handle(:outgoing_ctcp, target, text)

    report_string = @silent ? '' :  "{#{target}}  [#{@me} #{text}]"
    privmsg(target, "\001#{text}\001", report_string)
  end

  # Calls :outgoing_act handler, then ctcp to send a CTCP ACTION (text) to
  # a given user or channel (target)
  def act(target, text)
    # Dup strings so handler can filter safely
    target = target.dup
    text = text.dup

    handle(:outgoing_act, target, text)

    ctcp(target, "ACTION #{text}")
  end

  # Calls :outgoing_notice handler, then outputs raw NOTICE message
  def notice(target, text)
    # Dup strings so handler can filter safely
    target = target.dup
    text = text.dup

    handle(:outgoing_notice, target, text)

    report "{#{target}} -#{@me}- #{text}" unless @silent
    raw("NOTICE #{target} :#{text}", false)
  end

  # Calls :outgoing_ctcpreply handler, then uses notice method to send the
  # CTCP text
  def ctcpreply(target, text)
    # Dup strings so handler can filter safely
    target = target.dup
    text = text.dup

    handle(:outgoing_ctcpreply, target, text)

    report "{#{target}} [Reply: #{@me} #{text}]" unless @silent
    notice(target, "\001#{text}\001")
  end

  # Calls :outgoing_mode handler, then mode to set mode(s) on a channel
  # and possibly specific users (objects).  If modes and objects are blank,
  # just sends a raw MODE query.
  def mode(target, modes = '', objects = '')
    # Dup strings so handler can filter safely
    target = target.dup
    modes = modes.dup
    objects = objects.dup

    handle(:outgoing_mode, target, modes, objects)

    message = "MODE #{target}"
    message += " #{modes}" unless modes.to_s.empty?
    message += " #{objects}" unless objects.to_s.empty?
    raw message
  end

  # Calls :outgoing_join handler and then raw JOIN message for a given channel
  def join(target, pass = '')
    # Dup strings so handler can filter safely
    target = target.dup
    pass = pass.dup

    handle(:outgoing_join, target, pass)

    text = "JOIN #{target}"
    text += " #{pass}" unless pass.empty?
    raw text
  end

  # Calls :outgoing_part handler and then raw PART for leaving a given channel
  # (with an optional message)
  def part(target, text = '')
    # Dup strings so handler can filter safely
    target = target.dup
    text = text.dup

    handle(:outgoing_part, target, text)

    request = "PART #{target}";
    request += " :#{text}" unless text.to_s.empty?
    raw request
  end

  # Calls :outgoing_quit handler and then raw QUIT message with an optional
  # reason
  def quit(text = '')
    # Dup strings so handler can filter safely
    text = text.dup

    handle(:outgoing_quit, text)

    request = "QUIT";
    request += " :#{text}" unless text.to_s.empty?
    raw request
  end

  # Calls :outgoing_nick handler and then sends raw NICK message to change
  # nickname.
  def nick(new_nick)
    # Dup strings so handler can filter safely
    new_nick = new_nick.dup

    handle(:outgoing_nick, new_nick)

    raw "NICK :#{new_nick}"
  end

  # Identifies ourselves to the server.  Calls :outgoing_user and sends raw
  # USER command.
  def user(username, myaddress, address, realname)
    # Dup strings so handler can filter safely
    username = username.dup
    myaddress = myaddress.dup
    address = address.dup
    realname = realname.dup

    handle(:outgoing_user, username, myaddress, address, realname)

    raw "USER #{username} #{myaddress} #{address} :#{realname}"
  end

  # Sends a password to the server.  This *must* be sent before NICK/USER.
  # Calls :outgoing_pass and sends raw PASS command.
  def pass(password)
    # Dupage
    password = password.dup

    handle(:outgoing_pass, password)
    raw "PASS #{password}"
  end

  # Sends an op request.  Calls :outgoing_oper and raw OPER command.
  def oper(user, password)
    # Dupage
    user = user.dup
    password = password.dup

    handle(:outgoing_oper, user, password)
    raw "OPER #{user} #{password}"
  end

  # Gets or sets the topic.  Calls :outgoing_topic and raw TOPIC command
  def topic(channel, new_topic = nil)
    # Dup for filter safety in outgoing handler
    channel = channel.dup
    new_topic = new_topic.dup

    handle(:outgoing_topic, channel, new_topic)
    output = "TOPIC #{channel}"
    output += " #{new_topic}" unless new_topic.to_s.empty?
    raw output
  end

  # Gets a list of users and channels if channel isn't specified.  If channel
  # is specified, only shows users in that channel.  Will not show invisible
  # users or channels.  Calls :outgoing_names and raw NAMES command.
  def names(channel = nil)
    channel = channel.dup

    handle(:outgoing_names, channel)
    output = "NAMES"
    output += " #{channel}" unless channel.to_s.empty?
    raw output
  end

  # I don't know what the server param is for, but it's in the RFC.  If
  # channel is blank, lists all visible, otherwise just lists the channel in
  # question.  Calls :outgoing_list and raw LIST command.
  def list(channel = nil, server = nil)
    channel = channel.dup
    server = server.dup

    handle(:outgoing_list, channel, server)
    output = "LIST"
    output += " #{channel}" if channel
    output += " #{server}" if server
    raw output
  end

  # Invites a user to a channel.  Calls :outgoing_invite and raw INVITE
  # command.
  def invite(nick, channel)
    channel = channel.dup
    server = server.dup

    handle(:outgoing_invite, nick, channel)
    raw "INVITE #{nick} #{channel}"
  end

  # Kicks the given user from the channel with the optional comment.  Calls
  # :outgoing_kick and issues a raw KICK command.
  def kick(nick, channel, comment = nil)
    nick = nick.dup
    channel = channel.dup
    comment = comment.dup

    handle(:outgoing_kick, nick, channel, comment)
    output = "KICK #{channel} #{nick}"
    output += " :#{comment}" unless comment.to_s.empty?
    raw output
  end

end

end
