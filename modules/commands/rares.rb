module KekBot
  module Rares
    extend Discordrb::Commands::CommandContainer
    #list collectibles
    command(:rares, description: "list what rares you own") do |event|
      #get user
      user = $db["users"][event.user.id.to_s]

      #TODO - replace all this junk with #split_send

      #init list with intro text
      list = "#{event.user.mention}\'s `#{user["collectibles"].length.to_s}` #{$db["collectiblesName"]}s:\n\n"

      #buffer our output in case we go over 2k characters
      user["collectibles"].each do |x|

        #output string
        addition = "`#{$db["collectibles"][x]["description"]}`"

        #if our next addition will go over our 2000 char buffer, spit out the list and clear the buffer
        if (addition.length + list.length) > 2000
          event.respond(list)
          list = ""
        end

        #add next addition
        list << "#{addition}  "

      end

      #output list / end of list
      event.respond(list)

      #some extra help text
      event << "\nInspect a #{$db["collectiblesName"]} in your inventory with `.show [description]`."
    end
  end
end
