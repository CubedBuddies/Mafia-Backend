Rails.application.routes.draw do
  post '/games', to: 'games#create'
  get  '/games/:id', to: 'games#show'

  post '/games/:id/start', to: 'games#start'

  post '/games/:id/players', to: 'games#add_player'
  post '/games/:id/events', to: 'games#add_event'
end
