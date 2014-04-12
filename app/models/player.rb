class Player < ActiveRecord::Base
    
  validates_uniqueness_of :espn_id
  
  # Contracts and teams
  has_many :contracts
  has_many :teams, through: :contracts
  
  # Appearances
  has_many :appearances
  
  # Full statistics
  def stat(key)
    return appearances.map{|a| a.stat(key) ? a.stat(key) : 0}.reduce(:+)
  end
  
  # Paginate and sort
  def self.paginate_and_sort(sort)
    players = Player.all
    players = players.sort_by{|p| -p.stat(sort)} if sort # single parameter sort
    return players
  end
  
  # Score from regression coeffs
  # Basically a calculation of how many goals
  # the player has contributed
  def score
    score = stat("G")
    score += 0.239908 * stat("SG") # shots on goal
    score += 0.198056 * stat("SV") # saves
    score += 0.588098 * stat("A") # assists
    score -= 0.488015 * stat("RC") # red cards (negative)
    return score
  end
end
