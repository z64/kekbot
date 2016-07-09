module KekBot
  module Submit
    extend Discordrb::Commands::CommandContainer
    extend Tools
    command(:submit, min_args: 2, description: "adds a rare to the $db", usage: ".submit [url] [description]") do |event, url, *description|
      description = description.join(' ')

      #for the time being, only allow lowercase submissions
      description = description.downcase

      $db['collectibles'].each do |key, data|
        if data['url'] == url
          event << "This collectible already exists under a different name!"
        end
        if data['description'] == description
          event << "A collectible already exists with this description."
        end
      end

      #write new collectible
      $db['collectibles'][Digest::SHA1.hexdigest(url)] = { "description" => description, "timestamp"=> Time.now, "author" => event.user.id, "owner" => nil, "url" => url, "visible" => false, "unlock" => 0, "value" => 0 }

      #output success
      event << "**Thank you #{event.user.mention}!**"
      event << "Submitted rare: `#{description}`"

      #let admins know a collectible was submitted
      if event.channel.id != DEBUGCHANNEL
        event.bot.send_message(DEBUGCHANNEL, "`#{event.user.name} [#{event.user.id}]` submitted rare: `#{description}` :smile:\n#{url}")
      end

      #stats
      $db['stats']['submissions'] += 1
      save
      nil
    end
  end
end
