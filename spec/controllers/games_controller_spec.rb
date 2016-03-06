# == Schema Information
#
# Table name: games
#
#  id         :integer          not null, primary key
#  token      :string(255)
#  status     :string(255)
#  data       :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  describe '#create' do
    subject { post :create }

    it 'does something' do
      subject
    end
  end

  describe  '#show' do
    subject { get :show }
  end

  describe '#start' do
    subject { post :start }
  end

  describe '#add_player' do
    let(:params) { }

    subject { post :add_player, params }

  end

  describe '#add_event' do
    let(:params) { }

    subject { post :add_event, params }

  end
end
