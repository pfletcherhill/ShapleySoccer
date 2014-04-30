# Premier league season
(Date.parse("August 17, 2013")..Date.today).each do |date|
  Game.fetch_games_by_date(date)
end

Game.find_each do |g|
  g.integrate_timeline_from_xml
  g.increment_coalitions
end
