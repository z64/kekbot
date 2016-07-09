module KekBot
  module Give
    extend Discordrb::Commands::CommandContainer
    command(:give, min_args: 2,  description: "give currency") do |event, to, value|
      #convert value to integer
      value = value.to_i

      #pick up user
      fromUser = $db["users"][event.user.id.to_s]

      #return if invalid user
      if fromUser.nil?
        event << "User does not exist, or hasn't `.register`ed yet. :x:"
        return
      end

      #check if they have enough first
      if (fromUser["stipend"] - value) < 0
        event << "You do not have enough #{$db["currencyName"]} to make this transaction. :disappointed_relieved:"
        return
      end

      #flattery won't get you very far with KekBot
      if event.bot.parse_mention(to).id == event.bot.profile.id
        event << "Wh-... wha.. #{event.user.on(event.server).display_name}-senpai...*!*"
        event << "http://i.imgur.com/nxMsRS5.png"
        return
      end

      #pick up user to receive currency
      toUser = $db["users"][event.message.mentions.at(0).id.to_s]

      #check that they exist
      if toUser.nil?
        event << "User does not exist, or hasn't `.register`ed yet. :x:"
        return
      end

      #you can't give keks to yourself
      if fromUser == toUser
        event << "https://media.giphy.com/media/yidUzkciDTniZ7OHte/giphy.gif"
        return
      end

      #transfer keks
      fromUser["stipend"] -= value
      toUser["bank"] += value

      #update user stats
      toUser["currencyReceived"] += value
      toUser["karma"] += 1

      #update server stats
      $db['stats']['currencyTraded'] += value

      #notification
      event << "**#{event.user.on(event.server).display_name}** awarded **#{event.message.mentions.at(0).on(event.server).display_name}** with **#{value.to_s} #{$db["currencyName"]}** :joy: :ok_hand: :fire:"

      #unlock
      $db['collectibles'].each do |id, data|

        #check if collectible is hidden, and we've passed its
        if ($db['stats']['currencyTraded'] >= data['unlock']) & (data['unlock'] != 0) & !data['visible']

          #make the collectible available
          data['visible'] = true

          #announce
          event << "***Collectible Unlocked:*** `#{data['description']}` :confetti_ball:"
          event << "Use `.claim #{data["description"]}` to claim this #{$db["collectiblesName"]} for: **#{data["value"].to_s} #{$db["currencyName"]}!**"
          event << data['url']

          #announce in DEBUGCHANNEL
          event.bot.send_message(DEBUGCHANNEL, "Collectible `#{data['description']}` unlocked by `#{event.user.name} (#{event.user.id})`!")
        end
      end
      save
      nil
    end
  end
end
