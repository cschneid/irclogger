# Wire up the paths
Dir[File.dirname(__FILE__) + '/vendor/*/lib'].each { |d| $:.unshift d }
$:.unshift File.dirname(__FILE__) + '/lib'

require 'sinatra'
require 'date'
require 'helpers'
require 'partials'

# set :raise_errors, true
# set :show_exceptions, true

## DB ###########################
require 'sequel'
DB = Sequel.connect 'mysql://root@localhost/irclogs'
class Message < Sequel::Model(:irclog)
  def message_type
    return "msg" if msg?
    return "info" if info?
    ""
  end

  def msg?
    ! nick.empty?
  end

  def info?
    ! msg?
  end

  def self.find_by_channel_and_date(channel, date)
    day_after = date + 1

    filter(:timestamp > Time.local(date.year, date.month, date.day).to_i).
      filter(:timestamp < Time.local(day_after.year, day_after.month, day_after.day).to_i).
      filter(:channel => "##{channel}").
      order(:timestamp)
  end
end


## Helpers ###########################
helpers do
  include IRCLogger::Helpers
  include Sinatra::Partials
  include Rack::Utils
  alias_method :h, :escape_html

  def status_line(text)
    text.sub(/#.*$/, "")
  end

  def calendar(channel, date)
    cal = `cal #{date.month} #{date.year}`

    cal.gsub!(/\b(\d{1,2})\b/) do
      d = date.strftime("%Y-%m-#{$1.rjust 2, "0"}")
      current = "current" if date.to_s == d

      %Q{<a class="#{current}" href="/#{channel}/#{d}">#{$1}</a>}
    end

    next_date = date >> 1
    prev_date = date >> -1

    %Q{<a href="/#{channel}/#{prev_date}">&lt;</a>#{date.strftime("%B %Y").center(18)}<a href="/#{channel}/#{next_date}">&gt;</a>\n#{cal.split("\n")[1..-1].join("\n")}}
  end

  def plain_entry(message)
    buffer = [Time.at(message.timestamp).strftime("%H:%M")]

    if message.msg?
      buffer << "<#{message.nick}>"
      buffer << message.line
    else
      buffer << status_line(message.line)
    end

    buffer.join(" ")
  end
end

## Web ##########################
before do
  @channels = DB["SELECT channel FROM irclog GROUP BY channel"].inject([]) { |arr, row|
    arr << row[:channel] if (row[:channel] =~ /^#/ && row[:channel] != "#datamapper http://datamapper.")
    arr
  }
end

get '/' do
  @date = Date.today
  haml :index
end

get "/styles.css" do
  response["Content-Type"] = "text/css"
  sass :styles
end

get '/:channel' do
  redirect "/#{params[:channel]}/"
end

get '/:channel/' do
  @channel = params[:channel]
  redirect "/#{@channel}/#{relative_day('today')}"
end

get '/:channel/:date' do
  @date = Date.parse(params[:date])
  @channel = params[:channel]

  @messages = Message.find_by_channel_and_date(@channel, @date)

  if request.html?
    haml :channel
  else
    response["Content-Type"] = "text/plain"

    @messages.map do |message|
      plain_entry(message)
    end.join("\n")
  end
end

## Monkey Patching #############
class Fixnum
  def minutes
    self * 60
  end
end

class NilClass; def empty?; true; end; end

class Rack::Request
  def html?
    accept.any? { |content_type| content_type =~ /html/ }
  end
end
