class Coalition < ActiveRecord::Base
  
  # Associations
  has_and_belongs_to_many :players, -> { uniq }
  has_and_belongs_to_many :appearances, -> { uniq }
  
  # Find intersection of player coalitions
  def self.find_by_players(players = [])
    players.map{|p| p.coalitions}.inject(:&).first
  end
  
end
