require 'json'
require 'net/http'

class PopulateWords < ActiveRecord::Migration[7.0]
  def change
    begin
      uri = URI(ENV['PICTIONARY_WORDS_URL'])
      res = Net::HTTP.get_response(uri)
      return unless res.is_a?(Net::HTTPSuccess)
      if json = JSON.parse(res.body)['Pictionary']
        ['Easy', 'Medium', 'Hard'].each do |key|
          json[key].each do |word|
            Word.create!(name: word, difficulty: key)
          end
        end
      end
    rescue StandardError
      # Do nothing...
    end
  end
end
