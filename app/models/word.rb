class Word < ApplicationRecord
  scope :easy, -> { where(difficulty: "Easy") }
  scope :medium, -> { where(difficulty: "Medium") }
  scope :hard, -> { where(difficulty: "Hard") }

  ##
  # @return [Word] three random words, one of each difficulty.
  def self.random_option_set
    [Word.easy.sample, Word.medium.sample, Word.hard.sample]
  end
end
