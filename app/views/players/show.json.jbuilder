json.player do
  json.id @player.id
  json.name @player.name
  json.role @player.role
  json.state @player.state
  json.avatar_type @player.avatar_type
end