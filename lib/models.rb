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
