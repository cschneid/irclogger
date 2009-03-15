require 'rubygems'
# Wire up the paths
Dir[File.dirname(__FILE__) + '/vendor/*/lib'].each { |d| $:.unshift d }
$:.unshift File.dirname(__FILE__) + '/lib'


require 'sinatra'
require 'date'
require 'helpers'
require 'partials'

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
    ! nick.blank?
  end

  def info?
    ! msg?
  end
end


## Helpers ###########################
helpers do
  include IRCLogger::Helpers
  include Sinatra::Partials
  include Rack::Utils
  alias_method :h, :escape_html
end

## Web ##########################
get '/' do
  @channels = DB["SELECT channel FROM irclog GROUP BY channel"].inject([]) { |arr, row| 
    arr << row[:channel] if (row[:channel] =~ /^#/ && row[:channel] != "#datamapper http://datamapper.")
    arr 
  }

  erb :index
end

['/:channel', '/:channel/'].each do |url|
  get url do
    @channel = params[:channel]
    redirect "/#{@channel}/#{relative_day('today')}"
  end
end

get '/:channel/:date' do
  @channel = params[:channel]
  @date = params[:date]

  begin
    @base = Date.parse(@date)
  rescue
    redirect "/#{@channel}/#{relative_day(@date)}"
  end

  @day_before = (@base - 1)
  @day_after = (@base + 1)

  @begin = Time.local(@base.year, @base.month, @base.day)
  @end   = Time.local(@day_after.year, @day_after.month, @day_after.day)
  @messages = Message.filter(:timestamp > @begin.to_i).
                      filter(:timestamp < @end.to_i).
                      filter(:channel => "##{@channel}").
                      order(:timestamp)

  @urls = @messages.inject([]) do |arr, m|
    matches = m.line.scan IRCLogger::Helpers::AUTO_LINK_RE
    matches.each { |match| arr << (match[1] + match[2]) }
    arr
  end


  erb :log
end

## Monkey Patching #############
class Fixnum 
  def minutes
    self * 60
  end
end
