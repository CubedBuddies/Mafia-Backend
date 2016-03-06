class Round
  include ActiveModel::Model

  attr_accessor :votes
  attr_accessor :kills
  attr_accessor :players

  def update
  end

  def add_vote
  end

  def add_kill
  end
end