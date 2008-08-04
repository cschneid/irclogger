## DB ###########################
require 'sequel'
DB = Sequel.connect 'mysql://root@localhost/irclogs'


#  +-----------+-------------+------+-----+---------+----------------+
#  | Field     | Type        | Null | Key | Default | Extra          |
#  +-----------+-------------+------+-----+---------+----------------+
#  | id        | int(11)     | NO   | PRI | NULL    | auto_increment | 
#  | channel   | varchar(30) | YES  | MUL | NULL    |                | 
#--| day       | char(10)    | YES  |     | NULL    |                | 
#  | nick      | varchar(40) | YES  |     | NULL    |                | 
#  | timestamp | int(11)     | YES  |     | NULL    |                | 
#  | line      | text        | YES  |     | NULL    |                | 
#--| spam      | tinyint(1)  | YES  |     | 0       |                | 
#  +-----------+-------------+------+-----+---------+----------------+
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


class Channel < Sequel::Model(:channels)
  def self.get_channels 
    self.all.collect {|c| c.channel }
  end
end

