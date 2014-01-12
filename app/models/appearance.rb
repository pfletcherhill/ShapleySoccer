class Appearance < ActiveRecord::Base
  
  # Attributes:
  # integer: game_id
  # integer: player_id
  # integer: team_id
  # float: time_on
  # float: time_off
  attr_accessible :game_id, :player_id, :team_id, :time_on, :time_off

  # Associations
  belongs_to :player
  belongs_to :game
  belongs_to :team
  has_many :statistics
  
  # Substitutions
  has_one :substitution_in, foreign_key: :player_in_id, class_name: "Substitution"
  has_one :substitution_out, foreign_key: :player_out_id, class_name: "Substitution"
  
  validates_uniqueness_of :player_id, scope: [:game_id]
  
  # In, out substitutions
  def substitutions
    return [substitution_in, substitution_out].compact
  end
    
  def substitute? 
    return true if time_on > 0
    return false
  end
  
  # ["SH", "SG", "G", "A", "OF", "FD", "FC", "SV", "YC", "RC"]
  def stat(key)
    type = StatisticType.find_by_abbrev(key)
    stat = statistics.where(statistic_type_id: type.id).first
    if stat
      return stat.value
    else
      return 0
    end
  end
  
end
