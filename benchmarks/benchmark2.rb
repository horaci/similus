require '../lib/similus.rb'
require './custom_benchmark.rb'
require 'csv'
require 'pp'

# Configure redis
Similus.config do |config|
  config.backend = :redis
  config.redis_server = "localhost:6379"
  config.redis_db = 7
end

# Clear data
Similus.clear_database!

# Download entree-database
unless File.directory? "./entree-database"
  `wget http://archive.ics.uci.edu/ml/databases/entree/entree_data.tar.gz`
  `mkdir entree-database && cd entree-database && tar -zxvf ../entree_data.tar.g`
end

# Load chicago restaurants
restaurants = {}
print "Loading restaurants... "
CSV.open('./entree-database/entree/data/chicago.txt','r', :col_sep => "\t").each do |row|
  restaurants[row[0].to_i] = {
    :name => row[1],
    :features => row[2].split(" ").map(&:to_i)
  }
end

puts "Done!"

features = {}
print "Loading features... "
CSV.open('./entree-database/entree/data/features.txt','r', :col_sep => "\t").each do |row|
  features[row[0].to_i] = row[1]
end
puts "Done!"

# Load activity
users = {}
puts "Loading activity... "
Dir.glob(File.join("./entree-database/entree/session/", "session.*")).sort.each do |file|
  print "File #{file}: "
  pos = 0
  CSV.open(file,'r', :col_sep => "\t").each do |row|
    print "." if (pos += 1) % 100 == 0
    date = row.shift; user = row.shift; origin =row.shift
    pages = row.map { |x| x.gsub(/[^0-9]/, "").to_i }.reject { |x| x == 0 }

    users[user] ||= {
      :pages => [],
      :landings => [],
    }
    users[user][:pages] += pages
    users[user][:landings] << pages.last if pages.last > 0 

    pages.each do |page|
      Similus.add_activity(["User",user], :view, ["Restaurant",page])
    end
  end
  puts " Done!"
end

count = 0
total_score = 0
users.each do |user_key,user|
  break if (count += 1) > 500 # First 500 users only
  best_score = 0
  best_choice = nil
  Similus.recommended_for(["User",user_key]).each do |rec|
    user[:landings].each do |landing|
      rfm = (restaurants[rec[:id].to_i][:features] & restaurants[landing.to_i][:features]).size
      if rfm > best_score
        best_score = rfm
        best_choice = rec[:id].to_i
      end
    end
  end

  print "#{best_score},"
  total_score += best_score
end

puts " Done! --- Total: #{total_score}"

# control data




