namespace :quickstart  do
  task :seed => :environment do
    puts "Seeding database"

    Tweet.create(
      content: "Content: #{SecureRandom.hex}",
      author: "Person #{SecureRandom.hex}"
    )
    tweets = Tweet.all
    puts "> #{tweets.to_json}"
    puts "> finished"
  end
end