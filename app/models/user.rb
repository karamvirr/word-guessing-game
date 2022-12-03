class User < ApplicationRecord
  belongs_to :room, optional: false
  before_validation :initialize_slug

  def clear_score
    update!(score: 0)
  end

  def set_score(score)
    update!(score: score)
  end

private
  def initialize_slug
    return if self.slug.present?
    return unless self.name.present?
    self.slug = self.name.parameterize
  end
end
