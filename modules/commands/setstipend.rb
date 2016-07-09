module KekBot
  module Setstipend
    extend Discordrb::Commands::CommandContainer
    command(:setstipend, min_args: 1, description: "sets all users stipend values") do |event, value|
      break unless event.channel.id == DEBUGCHANNEL

      #get integer
      value = value.to_i

      #update all users
      $db["users"].each do |id, data|
        data["stipend"] = value
      end

      #notification
      event << "All stipends set to `#{value.to_s}`"
      save
      nil
    end
  end
end
