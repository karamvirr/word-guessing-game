# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing words
Word.destroy_all

# Easy words (25 words)
easy_words = [
  "basketball",
  "jacket",
  "swing",
  "fork",
  "orange",
  "house",
  "book",
  "hippo",
  "fish",
  "bird",
  "elephant",
  "apple",
  "chair",
  "button",
  "lamp",
  "pencil",
  "moon",
  "owl",
  "flower",
  "neck",
  "mitten",
  "shoe",
  "cup",
  "branch",
  "rocket"
]

# Medium words (25 words)
medium_words = [
  "baseball",
  "money",
  "bicycle",
  "rainbow",
  "magnet",
  "germ",
  "fire hydrant",
  "guitar",
  "sunglasses",
  "castle",
  "volcano",
  "penguin",
  "sandwich",
  "helicopter",
  "dinosaur",
  "octopus",
  "computer",
  "spaceship",
  "waterfall",
  "quicksand",
  "mushroom",
  "kangaroo",
  "light bulb",
  "hamburger",
  "sunset"
]

# Hard words (25 words)
hard_words = [
  "drip",
  "back flip",
  "stuffed animal",
  "cliff diving",
  "lunar rover",
  "constellation",
  "calm",
  "sandbox",
  "fast food",
  "border",
  "neighborhood",
  "washing machine",
  "tow truck",
  "somersault",
  "tearful",
  "movie",
  "centipede",
  "blush",
  "parallelogram",
  "coastline",
  "trampoline",
  "internet",
  "best friend",
  "laboratory",
  "gymnasium"
]

# Create words with their difficulty levels
easy_words.each do |word|
  Word.create!(name: word, difficulty: "Easy")
end

medium_words.each do |word|
  Word.create!(name: word, difficulty: "Medium")
end

hard_words.each do |word|
  Word.create!(name: word, difficulty: "Hard")
end

puts "Seeded #{Word.count} words:"
puts "- Easy: #{Word.where(difficulty: 'Easy').count}"
puts "- Medium: #{Word.where(difficulty: 'Medium').count}"
puts "- Hard: #{Word.where(difficulty: 'Hard').count}"
