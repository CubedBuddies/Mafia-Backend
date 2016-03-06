Rails.application.routes.draw do
  post '/games', to: 'games#create'
  get  '/games/:token', to: 'games#show'

  post '/games/:token/start', to: 'games#start'

  post '/games/:token/players', to: 'games#add_player'
  post '/games/:token/events', to: 'games#add_event'
end
