class User < ApplicationRecord
  belongs_to :room, optional: false
  before_validation :initialize_slug

private
  def initialize_slug
    return if self.slug.present?
    self.slug = self.name.parameterize
  end
end
