class ImportPremierLeagueTeams < ActiveRecord::Migration
  def change
    table_link = "http://espnfc.com/tables?league=eng.1&cc=5901"
    agent = Mechanize.new
    table = agent.get(table_link)
    table.search("tbody a").each do |a|
      id = a["href"].split("_/id/", 2).last.split("/", 2).first if a["href"]
      Team.create(espn_id: id, name: a.text)
    end
    
    api_teams = [
      ["Manchester City", "4472bef8-8d80-4c13-86b6-b1c60e021724"],
      ["Norwich City", "b61fa01c-1891-49ff-973a-23d4b14fc4fb"],
      ["Stoke City", "f31c42a3-6795-4882-ac06-18b4bfbff1d5"],
      ["Tottenham Hotspur", "e5de594d-65ce-432d-9704-4e3f7bb4a339"],
      ["Manchester United", "e9eeeab2-3bd2-4af5-8d28-93b5d8163dd1"],
      ["West Ham United", "1f81c3b0-1f1f-4225-9d6e-07885c1db509"],
      ["Chelsea", "618e7f40-7a78-47de-afcf-3ad1fee9f677"],
      ["Newcastle United", "6dedf5aa-fb54-49fd-b1b9-a58af93036df"],
      ["Aston Villa", "cff01c6a-797a-437b-9173-47e8d8c2d8c5"],
      ["Sunderland", "3541a5de-79cd-43ff-a1e8-bdb1416ad8da"],
      ["Arsenal", "0b97014f-1a82-46d5-bfbf-89857ef8f44a"],
      ["Fulham", "3a14bf84-1f10-4b73-8535-4d54e8a56ae5"],
      ["Liverpool", "48afd607-eda9-4db8-9125-380bc78612d2"],
      ["Southampton", "184f5fa9-4f5d-440a-942d-200a907d95db"],
      ["Everton", "04e7324b-7946-4863-891a-606e64eafdf0"],
      ["Cardiff City", "82b01d14-2043-480f-850c-b3bce83b7246"],
      ["Crystal Palace", "19d319d4-8fa8-4237-bf0d-3e07b5710c46"],
      ["Swansea City", "0ab9e882-01ad-47ad-ae8f-79c11e4f294f"],
      ["West Bromwich Albion", "dc6d86cb-1be3-4930-9209-d0a9c1cd25db"],
      ["Hull City", "c3142cba-2ee8-4645-9234-61dfd7f6c6c9"]
    ]
    
    api_teams.each do |name, id|
      team = Team.find_by(name: name)
      team.api_id = id
      team.save
    end
        
  end
end
