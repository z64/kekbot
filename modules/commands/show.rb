module KekBot
  module Show
    extend Discordrb::Commands::CommandContainer
    extend Tools
    require_relative '../tools.rb'
    command(:show, min_args: 1, description: "displays a rare, or tells you who owns it", usage: ".show [description]") do |event, *description|
      description = description.join(' ')

      #get user
      user = $db["users"][event.user.id.to_s]

      #look for our collectible, and do checks
      collectible = getCollectible(description)

      #check collectible doesn't exist, or is hidden
      if collectible.nil? | !collectible['data']['visible']
        event << "The #{$db["collectiblesName"]} `#{description}` doesn't exist, or isn't in your inventory."
        return
      end

      #output the collectible if its ours
      if !user['collectibles'].grep(collectible['id']).empty?
        event << "#{event.user.mention}\'s `#{description}`: "
        event << collectible['data']['url']
        return
      end

      #don't show it if it exists, but is claimed by someone else
      if !collectible['data']['owner'].nil?
        event << "`#{description}` is a claimed #{$db["collectiblesName"]}! :eyes:"
        return
      end

      #its unclaimed at this point - tell the user how to claim it
      event << "`#{description}` is an unclaimed #{$db["collectiblesName"]}! :eyes:"
      event << "Use `.claim #{collectible["data"]["description"]}` to claim this #{$db["collectiblesName"]} for: **#{collectible["data"]["value"].to_s} #{$db["currencyName"]}!**"
      event << collectible["data"]['url']
    end
  end
end
