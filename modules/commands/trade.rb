module KekBot
  module Trade
    extend Discordrb::Commands::CommandContainer
    command(:trade, description: "trade collectibles with other users", usage: ".trade @user [yourCollectible] / [theirCollectible]") do |event, *trade|

      #setup
      trade.shift #drop mention

      user_a = event.user
      user_a_db = $db['users'][user_a.id.to_s]

      user_b = event.message.mentions.at(0)
      user_b_db = $db['users'][user_b.id.to_s]
      trade = trade.join(' ').split("\s/\s").slice(0..1)

      #check that collectibles exist
      collectible_a = getCollectible(trade[0])
      if collectible_a.nil?
        event << "#{$db["collectiblesName"]} `#{trade[0]}` not found."
        return
      end

      collectible_b = getCollectible(trade[1])
      if collectible_b.nil?
        event << "#{$db["collectiblesName"]} `#{trade[1]}` not found."
        return
      end

      #check that each user owns the specified collectibles
      if user_a_db["collectibles"].grep(collectible_a['id']).empty?
        event << "You don't own that #{$db["collectiblesName"]}..!"
        return
      end

      if user_b_db["collectibles"].grep(collectible_b['id']).empty?
        event << "#{user_b_db} doesn't own that #{$db["collectiblesName"]}"
        return
      end

      event << "#{user_a.on(event.server).display_name} wants to trade his `#{collectible_a["data"]["description"]}` for your `#{collectible_b['data']["description"]}` #{event.message.mentions.at(0).mention}!"
      event << "Respond with `accept` or `reject` to complete the trade."

      event.message.mentions.at(0).await(:trade) do |subevent|

        if subevent.message.content == "accept"

          #perform the trade
          user_a_db["collectibles"].delete(collectible_a['id'])
          user_a_db["collectibles"] << collectible_b['id']

          user_b_db["collectibles"].delete(collectible_b['id'])
          user_b_db["collectibles"] << collectible_a['id']

          collectible_a['owner'] = user_b.id
          collectible_b['owner'] = user_a.id

          subevent.respond("Trade complete! :blush: :heart:")

          #stats
          $db['stats']['trades'] += 1

          save
          true

        elsif subevent.message.content == "reject"

          subevent.respond("#{user_b.on(event.server).display_name} has rejected your offer, #{event.user.mention} :x:")

          true

        else

          false

        end
      end
      nil
    end
  end
end
