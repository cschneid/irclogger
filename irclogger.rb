Dir[File.dirname(__FILE__) + '/vendor/*/lib'].each { |d| $:.unshift d }

require 'sinatra'
require 'cache'
require 'date'

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


helpers do
  include Sinatra::Cache
  include Rack::Utils
  alias_method :h, :escape_html

  def partial(template, *args)
    options = args.extract_options!
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << erb(template, options.merge(:layout =>
        false, :locals => {template.to_sym => member}))
    end.join("\n")
    else
      erb(template, options)
    end
  end

  def relative_day(day) 
    case day
    when "today": Date.today.strftime("%Y-%m-%d")
    when "yesterday": (Date.today - 1).strftime("%Y-%m-%d")
    else Date.today.strftime("%Y-%m-%d")
    end
  end
end

## Web ##########################
get '/' do
  @channels = DB["SELECT channel FROM irclog GROUP BY channel"].inject([]) { |arr, row| 
    arr << row[:channel] if row[:channel] =~ /^#/ 
    arr 
  }
  erb :index
end


## TODO: Make this DRY!!
get '/:channel' do
  @channel = params[:channel]
  redirect "/#{@channel}/#{relative_day('today')}"
end

## TODO: Make this DRY!!
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


  # Cache this if it isn't today.  Since old pages will never update...
  if @base == Date.today
    erb :log
  else
    STDERR << "Rendering log #{request.path_info}\n"
    cache(erb :log)
  end
end

## Monkey Patching #############
class Fixnum 
  def minutes
    self * 60
  end
end
