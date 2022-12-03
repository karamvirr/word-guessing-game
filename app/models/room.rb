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
    update!(current_word: word, game_started: true)
  end

  def end_game
    update!(current_word: nil, game_started: false)
    # self.users.each do |user|
    #   user.update!(score: 0)
    # end
  end

  def can_draw?(id)
    (id == self.drawer_id) && self.game_started?
  end

  def correct_guess?(guess)
    self.current_word == guess
  end

  # Returns the user removed from room.
  def remove_user(user)
    return user if user.nil? || !self.users.include?(user)

    # argument is passed-by-value
    self.users.find_by(id: user.id).destroy!
  end

  # Sets and returns the user model record of the next drawer.
  # If room contains no users, nil is returned.
  # If room contains only one user, that user record is returned.
  def set_next_drawer
    return if self.users.empty?
    if self.drawer_id.nil?
      update!(drawer_id: self.users.first.id)
      return self.users.first
    end
    unless self.users.map(&:id).include?(self.drawer_id)
      # if we are here it probably means the current drawer left the room.
      update!(drawer_id: self.users.first.id)
      return
    end

    index = self.users.map(&:id).index(self.drawer_id)
    update!(drawer_id: self.users[(index + 1) % self.users.count].id)
    self.users[(index + 1) % self.users.count]
  end

private
  def initialize_slug
    return if self.slug.present?
    self.slug = SecureRandom.urlsafe_base64(5).downcase
  end
end
