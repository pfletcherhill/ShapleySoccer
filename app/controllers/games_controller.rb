class GamesController < ApplicationController
  
  def index
    @games = Game.order("date").group_by{|game| game.date}
  end
  
  def show
    @game = Game.find(params[:id])
  end
  
  def process_csv
    file = Game.generate_diffs_csv
    send_data file, type: "text/csv", filename: 'game_diffs.csv'
  end
  
end
