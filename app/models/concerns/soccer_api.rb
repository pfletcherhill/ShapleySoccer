module SoccerAPI
  extend ActiveSupport::Concern

  included do
    
    EPA = "d8ddadd3-9a93-46bc-82b2-bc88c08b7255" # English Premier League ID
    EPA_START = Date.parse("August 17, 2013")
    API_PREFIX = "https://api.sportsdatallc.org/soccer-t2/eu/"
    API_SUFFIX = "?api_key=#{ENV['SPORTS_DATA_KEY']}"
    
    def self.api_url(string)
      API_PREFIX + string + API_SUFFIX
    end
    
    def api_url
      Game.api_url("matches/#{self.api_id}/summary.xml")
    end
    
    # Only loops over EPA games for now
    def self.schedule_by_date(date)
      require 'open-uri'
      begin
        date = date.strftime("%Y/%m/%d")
        url = self.api_url("matches/#{date}/schedule.xml")
        xml = Nokogiri::XML(open(url))
        xml.remove_namespaces!
        xml.xpath("//match[./tournament[@id='#{EPA}']]").each do |match|
          home = Team.find_by(api_id: match.xpath("./home").attr("id").to_s)
          away = Team.find_by(api_id: match.xpath("./away").attr("id").to_s)        
          date = Date.parse(match.attr("scheduled"))
          Game.create(home_team: home, away_team: away, date: date, api_id: match.attr("id").to_s)
        end
      rescue => e
        print  "ERROR parsing game: #{e}\n"
      end
    end
    
    def scrape_from_api
      require 'open-uri'
      begin
        url = Game.api_url("matches/#{self.api_id}/summary.xml")
        xml = Nokogiri::XML(open(url))
        File.open("lib/data/epa/#{self.date.to_s}-#{self.api_id}.xml", "w+") {|file| xml.write_xml_to(file)}
      rescue => e
        print "ERROR scraping from api: #{e}\n"
      end
    end
    
  end
  
end