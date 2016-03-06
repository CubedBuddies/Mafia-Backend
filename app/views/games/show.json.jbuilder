json.game do
  json.token @game.token
  json.state @game.state
  json.created_at @game.created_at
  json.updated_at @game.updated_at

  json.rounds @game.rounds do |round|
    json.player_ids round['player_ids']
    json.votes      round['votes']
    json.kills      round['kills']
    json.created_at round['created_at']
    json.expires_at round['expires_at']
  end

  json.players @game.players do |player|
    json.name player.name
    json.role player.role
    json.state player.state
    json.avatar_type player.avatar_type
  end
end