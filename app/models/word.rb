class Word < ApplicationRecord
  scope :easy, -> { where(difficulty: "Easy").pluck(:name, :difficulty) }
  scope :medium, -> { where(difficulty: "Medium").pluck(:name, :difficulty) }
  scope :hard, -> { where(difficulty: "Hard").pluck(:name, :difficulty) }

  ##
  # @return [Word] three random words, one of each difficulty.
  def self.random_option_set
    [Word.easy.sample, Word.medium.sample, Word.hard.sample]
  end
end
