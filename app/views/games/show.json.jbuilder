json.game do
  json.token @game.token
  json.state @game.state
  json.winner @game.winner
  json.created_at @game.created_at
  json.updated_at @game.updated_at

  json.rounds @game.rounds do |round|
    json.player_ids        round.fetch('player_ids')
    json.lynch_votes       round.fetch('lynch_votes')
    json.lynched_player_id round.fetch('lynched_player_id')
    json.kill_votes        round.fetch('kill_votes')
    json.killed_player_id  round.fetch('killed_player_id')
    json.created_at        round.fetch('created_at')
    json.expires_at        round.fetch('expires_at')
  end

  json.players @game.players do |player|
    json.id player.id
    json.name player.name
    json.role player.role
    json.state player.state
    json.avatar_type player.avatar_type
  end
end