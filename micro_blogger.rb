require 'jumpstart_auth'
require 'bitly'
require 'klout'

class MicroBlogger
  attr_reader :client

  def initialize
    puts "Initializing..."
    @client = JumpstartAuth.twitter
    Klout.api_key = 'xu9ztgnacmjx3bu82warbr3h'
  end

  def tweet(message)
    if message.length <= 140
      client.update(message)
    else
      puts "Tweet not posted. Message longer than 140 characters."
    end
  end

  def dm(target, message)
    puts "Trying to send #{target} this direct message:"
    puts message
    if followers_list.include?(target)
      tweet("d @#{target} #{message}")
    else
      puts "#{target} is not following you. Cannot send DM."
    end
  end

  def followers_list
    screen_names = []
    client.followers.map do |follower|
      screen_names << client.user(follower).screen_name
    end
    screen_names
  end

  def friends_list
    friends = []
    client.friends.map do |friend|
      friends << client.user(friend)
    end
    friends
  end

  def friends_screen_names
    friends_list.map { |friend| friend.screen_name }
  end

  def klout_score
    friends_screen_names.each do |sn|
      klout_id = Klout::Identity.find_by_screen_name(sn)
      user = Klout::User.new(klout_id.id)
      puts sn
      puts user.score.score.to_s + "\n\n"
    end
  end

  def spam_my_followers(message)
    followers_list.each do |follower|
      dm(follower, message)
    end
  end

  def everyones_latest_tweet
    sorted_friends = friends_list.sort_by { |friend| friend.screen_name.downcase }
    sorted_friends.each do |friend|
      formatted_time = friend.status.created_at.strftime("%A, %b %d")
      puts friend.name + " said this on " + formatted_time + "..."
      puts friend.status.text + "\n\n"
    end
  end

  def shorten(original_url)
    Bitly.use_api_version_3
    bitly = Bitly.new("hungryacademy", "R_430e9f62250186d2612cca76eee2dbc6")
    puts "Shortening this URL: #{original_url}"
    return bitly.shorten(original_url).short_url
  end

  def run
    puts "Welcome to the JSL Twitter Client!"
    command = ""
    while command != "q"
      printf "enter command: "
      input = gets.chomp
      parts = input.split(" ")
      command = parts[0]
      case command
      when 'q' then puts "Goodbye!"
      when 't' then tweet(parts[1..-1].join(" "))
      when 'dm' then dm(parts[1], parts[2..-1].join(" "))
      when 'spam' then spam_my_followers(parts[1..-1].join(" "))
      when 'elt' then everyones_latest_tweet
      when 'turl' then tweet(parts[1..-2].join(" ") + " " + shorten(parts[-1]))
      else
        puts "Sorry, I don't know how to #{command}"
      end
    end
  end
end
