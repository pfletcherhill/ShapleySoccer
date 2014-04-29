# Premier league season
(Date.parse("August 17, 2013")..Date.today).each do |date|
  Game.fetch_games_by_date(date)
  #Game.schedule_by_date(date)
end

#Game.find_each{|g| g.integrate_from_api}
