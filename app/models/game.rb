class Game < ActiveRecord::Base
  
  # Attributes:
  # integer: home_team_id
  # integer: away_team_id
  # date: date
  # integer: espn_id
  attr_accessible :home_team_id, :away_team_id, :date, :espn_id
  
  # Teams
  belongs_to :away_team, class_name: "Team"
  belongs_to :home_team, class_name: "Team" 
  
  # Appearances and Substitutions
  has_many :appearances
  has_many :players, through: :appearances
  has_many :statistics, through: :appearances
  has_many :substitutions
  
  # Validations
  validates_uniqueness_of :espn_id
  
  # Array of away and home teams
  def teams
    return [away_team, home_team].compact
  end
  
  # Starter (appearances with time_on == 0)
  def starters
    return appearances.where(time_on: 0)
  end
  
  # Report link
  def espn_link
    return "http://espnfc.com/en/report/#{espn_id.to_s}/report.html"
  end
  
  # To string (Away team at Home team)
  def to_s
    return "#{away_team_name} #{away_goals_count}-#{home_goals_count} #{home_team_name}"
  end
  
  # Statistics link
  def espn_stats_link
    return "http://espnfc.com/en/gamecast/statistics/id/#{espn_id.to_s}/statistics.html"
  end
  
  # Away team name (error handling)
  def away_team_name
    return away_team.name if away_team
  end
  
  # Home team name (error handling)
  def home_team_name
    return home_team.name if home_team
  end
  
  # Goals
  def goals(team_id = nil)
    goal_type = StatisticType.where(abbrev: "G").first
    if goal_type
      return statistics.joins(:appearance).where(statistic_type_id: goal_type.id, appearances: {team_id: team_id}) if team_id
      return statistics.where(statistic_type_id: goal_type.id)
    end
  end
  
  # Away Goals
  def away_goals
    return goals(away_team_id)
  end
  
  def away_goals_count
    return away_goals.map{|g| g.value}.reduce(:+) || 0
  end
  
  # Home Goals
  def home_goals
    return goals(home_team_id)
  end
  
  def home_goals_count
    return home_goals.map{|g| g.value}.reduce(:+) || 0
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
  
  # parse from ESPN
  # teams, appearances (subs)
  def parse_from_espn
    agent = Mechanize.new
    begin
      parse_teams(agent)
      parse_appearances(agent)
      parse_stats(agent)
    rescue => e
      print  "ERROR parsing game #{id} (#{espn_link}): #{e}"
    end
  end
  
  # fill in home, away team info
  def parse_teams(agent = Mechanize.new)
    begin
      page = agent.get(espn_stats_link)
      home_id = page.search(".match .away")[0]["id"].split("teamId-", 2).last
      self.home_team = Team.where(espn_id: home_id).first
      away_id = page.search(".match .home")[0]["id"].split("teamId-", 2).last
      self.away_team = Team.where(espn_id: away_id).first
      self.save
    rescue => e
      print "ERROR parsing teams for game #{id} (#{espn_stats_link}): #{e}"
    end
  end
  
  # parse from ESPN
  # pulls starters, subs
  # creates appearances, subs
  def parse_appearances(agent = Mechanize.new)
    begin
      page = agent.get(espn_link)
      home_starters = page.search(".span-3.column .first a")[1..11]
      away_starters = page.search(".span-3.column .last a")[1..11]
      [home_starters, away_starters].compact.each_with_index do |starters, i|
        starters.each do |starter|
          id = starter["href"].split("_/id/", 2).last.split("/", 2).first
          player = Player.where(espn_id: id).first
          player = Player.create(espn_id: id, name: starter.text) unless player
          Appearance.create(game_id: self.id, player_id: player.id, 
                            team_id: i > 0 ? away_team_id : home_team_id,
                            time_on: 0)
        end
      end
      home_subs = page.search(".gamecast-stat-0")[0].search("td")
      away_subs = page.search(".gamecast-stat-1")[0].search("td")
      [home_subs, away_subs].compact.each_with_index do |subs, i|
        subs.each do |sub|
          time = sub.text.split("(", 2).last.split("')", 2).first.to_i
          substitution = Substitution.new(time: time, game_id: self.id,
                                          team_id: i > 0 ? away_team_id: home_team_id)
          sub.search("a").each_with_index do |subst, sub_index|
            id = subst["href"].split("_/id/", 2).last.split("/", 2).first
            player = Player.where(espn_id: id).first
            player = Player.create(espn_id: id, name: subst.text) unless player
            if sub_index == 0 # sub in
              appearance = Appearance.find_or_create_by(game_id: self.id, player_id: player.id,
                                team_id: i > 0 ? away_team_id : home_team_id,
                                time_on: time)
              substitution.player_in = appearance
            elsif sub_index == 1 # sub out
              appearance = appearances.where(player_id: player.id).first
              appearance.time_off = time
              appearance.save
              substitution.player_out = appearance
            end
            substitution.save
          end
        end
      end
    rescue => e
      print "ERROR parsing appearances for game #{id} (#{espn_link}): #{e}"
    end
  end
  
  # Parse goals
  def parse_stats(agent = Mechanize.new)
    begin
      page = agent.get(espn_stats_link)
      page.search(".mod-container .stat-table tr").each do |row|
        if link = row.search("td a").first # validate row
          id = link["href"].split("_/id/", 2).last.split("/", 2).first
          player = self.players.where(espn_id: id).first
          app = appearances.where(player_id: player.id).first if player
          if app # if player played
            stats_table_key = ["SH", "SG", "G", "A", "OF", "FD", "FC", "SV", "YC", "RC"]
            row.search("td")[3..12].each_with_index do |stat, i|
              stat_type = StatisticType.where(abbrev: stats_table_key[i]).first
              Statistic.create(statistic_type_id: stat_type.id, appearance_id: app.id,
                              value: stat.text.to_f) if stat_type && stat.text.to_i > 0
            end
          end
        end
      end
    rescue => e
      print "ERROR parsing goals for game #{id} (#{espn_link}): #{e}"
    end
  end
  
  # Diff row (for regressions)
  # row of the form ["SH", "SG", "G", "A", "OF", "FD", "FC", "SV", "YC", "RC"]
  def diff_array
    array = [self.id]
    home_stats = statistics.joins(:appearance).where(appearances: {team_id: home_team.id})
    away_stats = statistics.joins(:appearance).where(appearances: {team_id: away_team.id})
    ["SH", "SG", "G", "A", "OF", "FD", "FC", "SV", "YC", "RC"].each do |key|
      stat_type = StatisticType.find_by_abbrev(key)
      home_val = home_stats.where(statistic_type_id: stat_type.id).map{|s| s.value}.sum
      away_val = away_stats.where(statistic_type_id: stat_type.id).map{|s| s.value}.sum
      array << home_val - away_val
    end
    return array
  end
  
  # Ruby date object passed in
  # Fetch espn_id and date
  def self.fetch_games_by_date (fetch_date)
    link = "http://espnfc.com/scores/_/date/#{fetch_date.strftime('%Y%m%d')}/league/eng.1"
    agent = Mechanize.new
    begin
      page = agent.get(link)
      page.search(".gamebox").each do |fixture|
        game_link = fixture.search(".teams a").first["href"]
        id = game_link.split("/report/", 2).last.split("/", 2).first if game_link
        if id && id.to_i > 0
          game = Game.find_or_create_by(espn_id: id, date: fetch_date)
          game.parse_from_espn if game
        end
      end
    rescue => e
      print "ERROR fetching games for date #{fetch_date} (#{link}): #{e}"
    end
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
