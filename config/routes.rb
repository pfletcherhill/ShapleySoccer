Soccer::Application.routes.draw do
  
  resources :games, :players, :teams
  
  root 'games#index'
  
  get '/export_csv', to: 'games#process_csv'
  get '/scoring_index', to: 'players#scoring_index'
  
end
