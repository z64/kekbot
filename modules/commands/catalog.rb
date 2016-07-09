module KekBot
  module Catalog
    extend Discordrb::Commands::CommandContainer
    #list all collectibles
    command(:catalog, description: "lists all unclaimed rares") do |event|

      #TODO - replace all this junk with #split_send

      #intro text
      message = "**Unclaimed #{$db["collectiblesName"]}s**\nClaim any #{$db["collectiblesName"]} in the list below with `.claim [description]`.\n\n"

      #buffer our output in case we go over 2k characters
      $db["collectibles"].each do |id, data|

        #if next addition goes over the 2k buffer, spit it out and clear the buffer
        if (message.length + data["description"].length) > 2000
          event.respond(message)
          message = ''
        end

        #add next collectible to message if its unclaimed
        if (!data['owner'] & data['visible']) then message << "`#{data["description"]} (#{data["value"]})`  " end

      end

      #output list / end of list
      event.respond(message)
    end
  end
end
