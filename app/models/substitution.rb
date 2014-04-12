class Substitution < ActiveRecord::Base
  
  # Validations
  validates_uniqueness_of :player_in_id, scope: [:game_id, :player_out_id]
  validates_uniqueness_of :player_out_id, scope: [:game_id, :player_in_id]
  validates_presence_of :player_in_id, :player_out_id
  
  # Associations
  belongs_to :game
  belongs_to :team
  belongs_to :player_in, class_name: "Appearance"
  belongs_to :player_out, class_name: "Appearance"
  
  # Methods
  # Player names
  def player_in_name
    return player_in.try(:player).try(:name)
  end
  
  def player_out_name
    return player_out.try(:player).try(:name)
  end
  
end
