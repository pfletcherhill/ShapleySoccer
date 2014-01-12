class ImportPremierLeagueTeams < ActiveRecord::Migration
  def change
    table_link = "http://espnfc.com/tables?league=eng.1&cc=5901"
    agent = Mechanize.new
    table = agent.get(table_link)
    table.search("tbody a").each do |a|
      id = a["href"].split("_/id/", 2).last.split("/", 2).first if a["href"]
      Team.create(espn_id: id, name: a.text)
    end
  end
end
