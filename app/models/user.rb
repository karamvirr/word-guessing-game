class User < ApplicationRecord
  belongs_to :room, optional: false

  def clear_score
    update!(score: 0)
  end

  def set_score(score)
    update!(score: score)
  end

private
end
