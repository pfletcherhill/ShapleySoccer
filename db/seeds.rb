# Premier league season
(Date.parse("August 17, 2013")..Date.today).each do |date|
  Game.fetch_games_by_date(date)
end
