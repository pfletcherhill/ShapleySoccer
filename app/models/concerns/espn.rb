module ESPN
  extend ActiveSupport::Concern

  included do
    # Report link
    def espn_link
      return "http://espnfc.com/en/report/#{espn_id.to_s}/report.html"
    end
    
    # Statistics link
    def espn_stats_link
      return "http://espnfc.com/en/gamecast/statistics/id/#{espn_id.to_s}/statistics.html"
    end
    
    # parse from ESPN
    # teams, appearances (subs)
    def parse_from_espn(agent = Mechanize.new)
      print "Parsing Game #{self.id} from ESPN..."
      begin
        parse_teams(agent)
        parse_appearances(agent)
        parse_timeline
        # parse_stats(agent)
        print "DONE\n"
      rescue => e
        print  "ERROR parsing game #{id} (#{espn_link}): #{e}\n"
      end
    end

    # fill in home, away team info
    def parse_teams(agent = Mechanize.new)
      begin
        page = agent.get(self.espn_stats_link)
        home_id = page.search(".match .away")[0]["id"].split("teamId-", 2).last
        self.home_team = Team.where(espn_id: home_id).first
        away_id = page.search(".match .home")[0]["id"].split("teamId-", 2).last
        self.away_team = Team.where(espn_id: away_id).first
        self.save
      rescue => e
        print "ERROR parsing teams for game #{id} (#{espn_stats_link}): #{e}"
      end
    end

    def parse_timeline
      begin
        require 'open-uri'
        print "Parsing timeline for game #{id}..."
        url = "http://www.espnfc.com/gamepackage10/data/timeline?gameId=#{espn_id}"
        xml = Nokogiri::XML(open(url))
        File.open("lib/data/epa/#{self.date.to_s}-#{self.espn_id}.xml", "w+") {|file| xml.write_xml_to(file)}
        print "DONE\n"
      rescue => e
        print "ERROR parsing timeline for game #{id} (#{url}): #{e}"
      end
    end
    
    def integrate_timeline_from_xml
      begin
        xml = Nokogiri::XML(File.read("lib/data/epa/#{self.date.to_s}-#{self.espn_id}.xml"))
        xml.remove_namespaces!
        xml.xpath("//event").each do |event|
          if event.attr("type").to_s == "goal"
            time = event.attr("clock").to_s
            name = event.text.split("<b>", 2).last.split("</b>", 2).first
            player = Player.find_by(name: name)
            app = appearances.find_or_create_by(player: player)
            Goal.create(appearance: app, time: time)
          end
        end
      rescue => e
        print "ERROR integrating timeline from XML: #{e}"
      end
    end
    
    def parse_gamecast
      begin
        require 'open-uri'
        print "Parsing gamecast for game #{id}..."
        url = "http://www.espnfc.com/gamepackage10/data/gamecast?gameId=#{espn_id}"
        xml = Nokogiri::XML(open(url))
        File.open("lib/data/epa/gamecast/#{self.date.to_s}-#{self.espn_id}.xml", "w+") {|file| xml.write_xml_to(file)}
        print "DONE\n"
      rescue => e
        print "ERROR parsing gamecast for game #{id} (#{url}): #{e}"
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
                appearance = appearances.find_by(player_id: player.id)
                if appearance
                  appearance.time_off = time
                  appearance.save
                end
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
            player = self.players.find_by(espn_id: id)
            app = appearances.find_by(player: player) if player
            if app # if player played
              stats_table_key = Statistic::TYPES
              row.search("td")[3..12].each_with_index do |stat, i|
                Statistic.create(stat_type: stats_table_key[i], appearance: app,
                                 value: stat.text.to_f) if stat.text.to_i > 0
              end
            end
          end
        end
      rescue => e
        print "ERROR parsing stats for game #{id} (#{espn_link}): #{e}"
      end
    end
    
    # Ruby date object passed in
    # Fetch espn_id and date
    def self.fetch_games_by_date (fetch_date)
      url = "http://espnfc.com/scores/_/date/#{fetch_date.strftime('%Y%m%d')}/league/eng.1"
      agent = Mechanize.new
      begin
        page = agent.get(url)
        page.search(".gamebox").each do |fixture|
          game_link = fixture.search(".teams a").first["href"]
          id = game_link.split("/report/", 2).last.split("/", 2).first if game_link
          if id && id.to_i > 0
            game = Game.find_or_create_by(espn_id: id, date: fetch_date)
            game.try(:parse_from_espn, agent)
          end
        end
      rescue => e
        print "ERROR fetching games for date #{fetch_date} (#{url}): #{e}"
      end
    end
  end
  
end