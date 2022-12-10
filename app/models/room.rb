class Room < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  before_validation :initialize_slug

  # time a player has to draw in seconds.
  TIME_LIMIT = 60

  has_many :users, -> {
    where.not(name: nil).order("id ASC")
  }

  has_many :users_in_staging, -> {
    where(name: nil)
  }, class_name: 'User'

  scope :scoreboard, -> {
    users.order("score DESC")
  }

  def scoreboard
    self.users.sort_by{ |u| -u.score }
  end

  def update_hint(guess)
    return if self.current_word.nil?

    updated_hint = self.hint
    guess.each_char.with_index do |char, index|
      if char == self.current_word[index]
        updated_hint[index] = char
      end
    end

    update!(hint: updated_hint)
  end

  def start_turn(word)
    word = word.strip.downcase
    update!(current_word: word, hint: word.gsub(/[\w]/, '-'))
  end

  def end_turn
    update!(current_word: nil, hint: nil, time_remaining: TIME_LIMIT)
    self.users.each do |user|
      user.update!(guessed_correctly: false)
    end
  end

  def start_game
    self.users.each do |user|
      user.set_score(0)
    end
    update!(game_started: true)
  end

  def end_game
    self.end_turn
    update!(round: 1, game_started: false)
  end

  def everyone_guessed_correctly?
    # self.users.count - 1 because the user currently drawing is excluded.
    self.users.count{ |u| u.guessed_correctly? } == (self.users.count - 1)
  end

  def can_draw?(id)
    (id == self.drawer_id) && self.game_started? && !self.current_word.nil?
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

  def decrement_time_remaining
    seconds = self.time_remaining
    update!(time_remaining: (seconds - 1))
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
    # made it back to the first user.
    if ((index + 1) % self.users.count) == 0
      self.update!(round: self.round + 1)
    end
    update!(drawer_id: self.users[(index + 1) % self.users.count].id)
    self.users[(index + 1) % self.users.count]
  end

private
  def initialize_slug
    return if self.slug.present?
    self.slug = SecureRandom.urlsafe_base64(5).downcase
  end
end
