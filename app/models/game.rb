class Game < ActiveRecord::Base
    
  include SoccerAPI
  include ESPN
  
  # Teams
  belongs_to :away_team, class_name: "Team"
  belongs_to :home_team, class_name: "Team" 
  
  # Appearances and Substitutions
  has_many :appearances
  has_many :players, through: :appearances
  has_many :statistics, through: :appearances
  has_many :goals, through: :appearances
  has_many :substitutions
  
  # Validations
  validates_uniqueness_of :espn_id, allow_nil: true
  validates_uniqueness_of :api_id, allow_nil: true
    
  # Array of away and home teams
  def teams
    return [away_team, home_team].compact
  end
  
  # Starter (appearances with time_on == 0)
  def starters
    return appearances.where(time_on: 0)
  end
  
  # To string (Away team at Home team)
  def to_s
    return "#{away_team_name} #{away_goals_count}-#{home_goals_count} #{home_team_name}"
  end
  
  # Away team name (error handling)
  def away_team_name
    return away_team.try(:name)
  end
  
  # Home team name (error handling)
  def home_team_name
    return home_team.try(:name)
  end
  
  # Goals by team
  def goals_by_team(team)
    return goals.where(appearance_id: appearances_with_options({team: team}).map{|a| a.id})
  end
  
  # Away Goals
  def away_goals
    return goals.where(appearance_id: appearances_with_options({team: away_team}).map{|a| a.id})
  end
  
  def away_goals_count
    return away_goals.count
  end
  
  # Home Goals
  def home_goals
    return goals.where(appearance_id: appearances_with_options({team: home_team}).map{|a| a.id})
  end
  
  def home_goals_count
    return home_goals.count
  end
  
  # Winner
  def winner
    diff = home_goals_count - away_goals_count
    if diff > 0
      return home_team
    elsif diff < 0
      return away_team
    else
      return nil
    end
  end
  
  # Loser
  def loser
    diff = home_goals_count - away_goals_count
    if diff > 0
      return away_team
    elsif diff < 0
      return home_team
    else
      return nil
    end
  end
      
  def appearances_with_options(options = {})
    apps = self.appearances
    
    # By team (home or away)
    if options[:team]
      apps = apps.where(team_id: options[:team].id)
    end
    
    # By time (at specified time)
    if options[:time]
      time = options[:time]
      apps = apps.where("time_on <= ? AND (time_off > ? OR time_off IS NULL)", time, time)
    end
    return apps
  end
  
  # Coalitions
  def coalitions
    self.teams.map{ |team|
      coalitions_by_team(team)
    }.inject(:+)
  end
  
  # TODO: Handle extra time
  # Returns coalitions of the form {[app_ids] => [minutes_count, scored, conceded]}
  def coalitions_by_team(team)
    hash = {}
    (1..90).each do |time|
      apps = appearances_with_options({team: team, time: time})
      app_ids = apps.map{|a| a.id}
      
      # Find goals count for current minute
      goals_for_count = goals_by_team(team).where(time: time).count
      opponent = (teams - [team]).first
      goals_against_count = goals_by_team(opponent).where(time: time).count
      
      # If hash has already initiated coalition
      if values = hash[app_ids]
        values[0] ? count = values[0] + 1 : count = 1
        goals_for_count = values[1] + goals_for_count if values[1]
        goals_against_count = values[2] + goals_against_count if values[2]
      else
        count = 1
      end
            
      # Add both to hash as [count, scored, conceded]
      hash[app_ids] = [count, goals_for_count, goals_against_count]
    end
    return hash.to_a
  end
  
  # For each set of appearance ids, find coalition (intersection)
  # of players.coalitions. Add appearances to coalition
  def increment_coalitions
    self.coalitions.each do |app_ids, value|
      apps = Appearance.where(id: app_ids)
      players = apps.map{|a| a.player}
      coalition = Coalition.find_by_players(players)
      unless coalition
        coalition = Coalition.new
        coalition.players << players
      end
      coalition.minutes ? coalition.minutes += value[0] : coalition.minutes = value[0]
      coalition.scored ? coalition.scored += value[1] : coalition.scored = value[1]
      coalition.conceded ? coalition.conceded += value[2] : coalition.conceded = value[2]
      coalition.appearances << apps # Add appearances to coalition
      coalition.save
    end
  end
  
  # Diff row (for regressions)
  # row of the form ["SH", "SG", "G", "A", "OF", "FD", "FC", "SV", "YC", "RC"]
  def diff_array
    array = [self.id]
    home_stats = statistics.joins(:appearance).where(appearances: {team_id: home_team.id})
    away_stats = statistics.joins(:appearance).where(appearances: {team_id: away_team.id})
    Statistic::TYPES.each do |key|
      home_val = home_stats.where(stat_type: key).map{|s| s.value}.sum
      away_val = away_stats.where(stat_type: key).map{|s| s.value}.sum
      array << home_val - away_val
    end
    return array
  end
  
  def self.generate_diffs_csv
    require 'csv'
    CSV.generate do |csv|
      csv << ["ID", "SH", "SG", "G", "A", "OF", "FD", "FC", "SV", "YC", "RC"]
      Game.find_each do |g|
        csv << g.diff_array
      end
    end
  end
end
