class Room < ApplicationRecord
  has_many :users
  validates :slug, presence: true, uniqueness: true
  before_validation :initialize_slug

private
  def initialize_slug
    return if self.slug.present?
    self.slug = SecureRandom.urlsafe_base64(5).downcase
  end
end
