class Team < ActiveRecord::Base

  # Games
  has_many :away_games, foreign_key: :away_team_id, class_name: "Game"
  has_many :home_games, foreign_key: :home_team_id, class_name: "Game"
  
  # Contracts and players
  has_many :contracts
  #has_many :players, through: :contracts
  
  # Appearances and Substitutions
  has_many :appearances
  has_many :players, -> { uniq }, through: :appearances
  has_many :substitutions
  
  # Validations
  validates_uniqueness_of :espn_id
  
  # Games
  def games
    away_games + home_games
  end
  
  # Mean score
  def mean_score
    return players.uniq.map{|p| p.score}.sum / players.uniq.count
  end
  
  # ESPN Link
  def espn_link
    return "http://espnfc.com/team/_/id/#{espn_id.to_s}"
  end
  
end
