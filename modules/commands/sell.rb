module KekBot
  module Sell
    extend Discordrb::Commands::CommandContainer
    command(:sell, min_args: 3, description: "create a sale", usage: ".sell [description] @user [offer]") do |event, *sale|

      #setup
      amount = sale.pop.to_i
      sale.pop #pop off mention
      description = sale.join(' ')
      buyer = event.message.mentions.at(0)
      seller = event.user
      buyer_db = $db['users'][buyer.id.to_s]
      seller_db = $db['users'][seller.id.to_s]
      collectible = getCollectible(description)

      #handle negative values
      if(amount < 0)
        event << "http://i.imgur.com/J1HocUj.png"
        return
      end

      #check collectible exists
      if collectible.nil?
        event << "This #{$db["collectiblesName"]} does not exist.. :eyes:"
        return
      end

      #check that you own what you want to sell
      if collectible['data']['owner'] != seller.id
        event << "You don't have this #{$db["collectiblesName"]}.. :eyes:"
        return
      end

      #check buyer can afford
      if amount > buyer_db['bank']
        event << "#{buyer.on(event.server).display_name} can not afford that sale.. :eyes:"
        return
      end

      #process sale
      event << "#{seller.on(event.server).display_name} wants to sell `#{description}` to #{buyer.on(event.server).display_name} for #{amount} #{$db["currencyName"]}! :incoming_envelope:"
      event << "#{buyer.mention}, type `accept` or `reject`"

      #await for accept / reject response
      buyer.await(:sale) do |subevent|

        if subevent.message.content == "accept"

          #users balance could have changed since sale created - double check we can afford it
          if amount > buyer_db["bank"]

            subevent.respond("#{buyer.on(event.server).display_name} can no longer afford that sale.. :eyes:")

          else #complete sale..

            #swap collectible between users
            seller_db["collectibles"].delete(collectible['id'])
            buyer_db["collectibles"] << collectible['id']
            collectible['owner'] = buyer.id

            #process currency transaction
            buyer_db["bank"] -= amount
            seller_db["bank"] += amount

            #output message
            subevent.respond("#{buyer.on(event.server).display_name} accepted your offer, #{event.user.mention}!")

            #stats
            $db['stats']['sales'] += 1
            $db['stats']['salesValue'] += amount

            save

          end

          #sale complete - destroy await
          true

        elsif subevent.message.content == "reject"

          subevent.respond("#{buyer.on(event.server).display_name} has rejected your offer, #{event.user.mention} :x:")

          #sale rejected - destroy await
          true

        else

          #message was something else; ignore it and keep await alive
          false

        end

      end
      nil
    end
  end
end
