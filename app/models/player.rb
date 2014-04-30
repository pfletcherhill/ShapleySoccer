class Player < ActiveRecord::Base
    
  validates_uniqueness_of :espn_id
  
  # Contracts and teams
  has_many :contracts
  has_many :teams, through: :contracts
  has_and_belongs_to_many :coalitions, -> { uniq }
  has_many :players, -> { uniq }, through: :coalitions
  
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
  
  def teammates
    self.players - [self]
  end
  
  def compute_value(coal_func = "value", max = self.teammates.length)
    self.value = coalitions.map{|c| c.send(coal_func)}.reduce(:+)
    (1..max).each do |n|
      print "Trying combinations of #{n} elements..."
      print "Score is currently #{self.value}..."
      teammates.combination(n).each do |combo|
        combos = ([coalitions] + combo.map{|c| c.coalitions}).inject(:&)
        combos.each do |c|
          self.value += (c.value / (n + 1))
        end
      end
      self.save # Save at end of each combination set
      print "DONE\n"
    end
    return value
  end
  
  def shapley_value(coal_func = "value")
    Player.shapley_values([self], coal_func).first[1]
  end
  
  def self.shapley_values(players_array = [], coal_func = "value")
    sums = {}
    players_array.each{|p| sums[p.id] = 0}
    players_array.permutation.to_a.each do |perm|
      perm.each_with_index do |player, i|
        now = Coalition.union_of_players(perm[0..i]).map{|c| c.send(coal_func)}.reduce(:+)
        if i > 0
          before = Coalition.union_of_players(perm[0..(i - 1)]).map{|c| c.send(coal_func)}.reduce(:+)
        else
          before = 0
        end
        sums[player.id] += now - before
      end
    end
    factorial = (1..players_array.count).inject(:*) || 1
    return sums.map{|id, sum| [id, sum / factorial]}
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
