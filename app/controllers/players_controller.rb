class PlayersController < ApplicationController
  
  def index
    @players = Player.paginate_and_sort(params[:sort])
    #@players = Kaminari.paginate_array(@players).page(1).per(50)
  end
  
  def scoring_index
    @players = Player.all.sort_by{|p| -p.score}
    render :index
  end
  
  def show
    @player = Player.find(params[:id])
  end
  
end
