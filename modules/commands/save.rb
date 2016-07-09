module KekBot
  module Save
    extend Discordrb::Commands::CommandContainer
    command(:save, description: "force database save") do |event|
      break unless event.channel.id == DEBUGCHANNEL
      save
      event << "**You have saved the keks..** :pray:"
    end
  end
end
