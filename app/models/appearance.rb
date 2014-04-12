class Appearance < ActiveRecord::Base
  
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
  
  def stat(key)
    stat = statistics.where(stat_type: key).first
    return stat ? stat.value : 0
  end
  
end
