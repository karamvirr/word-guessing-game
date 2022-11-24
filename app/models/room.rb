class Room < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  before_validation :initialize_slug

  has_many :users
  # has_one :host, class_name: "User", :dependent => :nullify
  # has_one :drawer, class_name: "User", :dependent => :nullify

private
  def initialize_slug
    return if self.slug.present?
    self.slug = SecureRandom.urlsafe_base64(5).downcase
  end
end
