class Room < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  before_validation :initialize_slug

  has_many :users, ->(user) {
    where.not(name: nil)
  }

  has_many :users_in_staging, -> (user) {
    where(name: nil)
  },
    class_name: 'User'


  def start_game(word)
    self.current_word = word
    self.game_started = true
  end

  def end_game
    self.current_word = nil
    self.game_started = false
  end

  # Sets and returns the user model record of the next drawer.
  # If room contains no users, nil is returned.
  # If room contains only one user, that user record is returned.
  def set_next_drawer
    return nil if self.users.empty?
    index = self.users.map(&:id).index(self.drawer_id)
    self.drawer_id = (index + 1) % self.users.count
    self.users[(index + 1) % self.users.count]
  end

private
  def initialize_slug
    return if self.slug.present?
    self.slug = SecureRandom.urlsafe_base64(5).downcase
  end
end
