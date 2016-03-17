# == Schema Information
#
# Table name: games
#
#  id         :integer          not null, primary key
#  token      :string(255)
#  state      :string(255)
#  winner     :string(255)
#  data       :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  render_views

  describe '#full_game_playthrough' do
    it 'runs through the game' do
      # Create game
      post :create

      game = Game.last
      token = JSON.parse(response.body)['game']['token']

      expect(token).to eq(game.token)
      expect(game.state).to eq('initializing')

      # Add players
      # fixture_file_upload('avatar.png', 'image/png')

      post :add_player, { token: token, player: { name: 'Rick Song' } }
      post :add_player, { token: token, player: { name: 'Charles Yeh' } }
      post :add_player, { token: token, player: { name: 'Priscilla Lok' } }
      post :add_player, { token: token, player: { name: 'Jenn Lee' } }
      post :add_player, { token: token, player: { name: 'Connie Yu' } }
      post :add_player, { token: token, player: { name: 'Christian Deonier' } }
      post :add_player, { token: token, player: { name: 'Isis Anchalee' } }

      get :show, { token: token }

      game.reload
      expect(game.players.count).to eq(7)

      # Adding duplicate player
      post :add_player, { token: token, player: { name: 'Isis Anchalee' } }

      get :show, { token: token }

      game.reload
      expect(game.players.count).to eq(7)

      # Remove a player
      players = game.players
      delete :remove_player, { token: token, player_id: players[-1].id }

      get :show, { token: token }

      game.reload
      expect(game.players.count).to eq(6)

      # Start the game
      Timecop.freeze(Time.utc(2016, 10, 31, 12, 0, 0))
      post :start, { token: token }

      game.reload
      expect(game.state).to eq('in_progress')
      expect(game.players.where(state: 'alive', role: 'mafia').count).to eq(2)
      expect(game.players.where(state: 'alive', role: 'townsperson').count).to eq(4)
      expect(game.players.where(state: 'alive').count).to eq(6)
      expect(game.current_round['created_at']).to eq(Time.utc(2016, 10, 31, 12, 0, 10).to_json)
      expect(game.current_round['expires_at']).to eq(Time.utc(2016, 10, 31, 12, 0, 40).to_json)
      expect(game.current_round['player_ids']).to match_array(game.players.pluck(:id))

      townspeople = game.players.where(role: 'townsperson').pluck(:id).map(&:to_s)
      mafia = game.players.where(role: 'mafia').pluck(:id).map(&:to_s)

      # Generate some votes
      post :add_event, { token: token, event: { name: 'lynch', source_player_id: townspeople[0], target_player_id: mafia[0] }}
      post :add_event, { token: token, event: { name: 'kill', source_player_id: mafia[0], target_player_id: townspeople[0] }}

      get :show, { token: token }

      game.reload
      expect(game.current_round['lynch_votes']).to eq({townspeople[0] => mafia[0]})
      expect(game.current_round['kill_votes']).to eq({mafia[0] => townspeople[0]})

      # Update the game again
      Timecop.freeze(Time.utc(2016, 10, 31, 12, 5, 0))
      get :show, { token: token }

      game.reload
      expect(game.previous_round['killed_player_id']).to eq(townspeople[0])
      expect(game.previous_round['lynched_player_id']).to eq(mafia[0])
      expect(game.players.where(state: 'alive', role: 'mafia').count).to eq(1)
      expect(game.players.where(state: 'alive', role: 'townsperson').count).to eq(3)
      expect(game.players.where(state: 'alive').count).to eq(4)

      expect(game.rounds.count).to eq(2)
      expect(game.current_round['player_ids']).to match_array(game.players.where(state: 'alive').pluck(:id))

      post :add_event, { token: token, event: { name: 'lynch', source_player_id: townspeople[1], target_player_id: mafia[1] }}
      post :add_event, { token: token, event: { name: 'lynch', source_player_id: townspeople[2], target_player_id: mafia[1] }}
      post :add_event, { token: token, event: { name: 'lynch', source_player_id: townspeople[3], target_player_id: townspeople[1] }}
      post :add_event, { token: token, event: { name: 'kill', source_player_id: mafia[1], target_player_id: townspeople[1] }}

      Timecop.freeze(Time.utc(2016, 10, 31, 12, 10, 0))
      get :show, { token: token }

      game.reload
      expect(game.players.where(state: 'alive', role: 'mafia').count).to eq(0)
      expect(game.players.where(state: 'alive', role: 'townsperson').count).to eq(2)
      expect(game.players.where(state: 'alive').count).to eq(2)
      expect(game.winner).to eq('townsperson')
      expect(game.state).to eq('finished')
    end
  end
end
