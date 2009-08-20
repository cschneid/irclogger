require 'rubygems'
# Wire up the paths
Dir[File.dirname(__FILE__) + '/vendor/*/lib'].each { |d| $:.unshift d }
$:.unshift File.dirname(__FILE__) + '/lib'

## Rack 0.9.1 fix ##############
#require 'rack/file'
#class Rack::File
#  MIME_TYPES = Hash.new { |hash, key|
#  Rack::Mime::MIME_TYPES[".#{key}"] }
#end

## Ruby 1.9.1 fixes
if RUBY_VERSION > '1.9'
  ## String#each needs to be aliased
  class String
    alias_method :each, :each_line
  end

  ## Ruby 1.9.1 also works best with thin
  require 'thin'
end

require 'sinatra'
require 'date'
require 'helpers'
require 'partials'
require 'json'

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

get '/:channel' do
  redirect "/#{params[:channel]}/"
end

get '/:channel/' do
  @channel = params[:channel]
  redirect "/#{@channel}/#{relative_day('today')}"
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

get '/:channel/slice/:from/:to' do
  @channel = params[:channel]
  @messages = Message.filter(:timestamp > params[:from]).
                      filter(:timestamp < params[:to]).
                      filter(:channel => "##{@channel}").
                      order(:timestamp).collect do |m|
		        {
			  :id        => m.id ,
			  :channel   => m.channel ,
			  :day       => m.day ,
			  :nick      => m.nick ,
			  :timestamp => m.timestamp ,
			  :line      => m.line ,
			  :spam      => m.spam ,
			  :permalink => "http://irclogger.com/#{@channel}/#{Time.at(m.timestamp).strftime("%Y-%m-%d")}#msg_#{m.timestamp}"
			}
		      end

  @messages.to_json	
end

## Monkey Patching #############
class Fixnum
  def minutes
    self * 60
  end
end
