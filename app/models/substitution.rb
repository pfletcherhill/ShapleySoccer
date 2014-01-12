class Substitution < ActiveRecord::Base
  
  # Attributes:
  # float: time
  # integer: player_in_id
  # integer: plyer_out_id
  # integer: game_id
  # integer: team_id
  attr_accessible :time, :player_in_id, :player_out_id, :game_id, :team_id
  
  # Validations
  validates_uniqueness_of :player_in_id, scope: [:game_id, :player_out_id]
  validates_uniqueness_of :player_out_id, scope: [:game_id, :player_in_id]
  validates_presence_of :player_in_id, :player_out_id
  
  belongs_to :game
  belongs_to :team
  belongs_to :player_in, class_name: "Appearance"
  belongs_to :player_out, class_name: "Appearance"
  
  # Player names
  def player_in_name
    return player_in.player.name if player_in
  end
  
  def player_out_name
    return player_out.player.name if player_out
  end
  
end
