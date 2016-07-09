module KekBot
  module Claim
    extend Discordrb::Commands::CommandContainer
    extend Tools
    #claim collectible
    command(:claim, min_args: 1, description: "claims an unclaimed rare", usage: ".claim [description]") do |event, *description|
      description = description.join(' ')

      #grab user
      user = $db['users'][event.user.id.to_s]

      #select collectible
      collectible = getCollectible(description)

      #error if collectible doesn't exist
      if (collectible.nil? | !collectible['data']['visible'])
        event << "This rare does not exist.. :eyes:"
        return
      end

      #check if its already claimed
      if !collectible['data']['owner'].nil?
        event << "`#{description}` is already claimed.. :eyes:"
        return
      end

      #make sure we can afford it
      if user['bank'] < collectible['data']['value']
        event << "Not enough **#{$db["currencyName"]}** in your **Dank Bank**.. :eyes:"
        return
      end

      #its unclaimed and we can afford it
      #perform transaction
      user['collectibles'] << collectible['id']
      user['bank'] -= collectible['data']['value']
      collectible['data']['owner'] = event.user.id
      save

      #output success
      event << "`#{description}` has been added to your `.rares`! :money_with_wings:"
    end
  end
end
