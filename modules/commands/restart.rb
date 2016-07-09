module KekBot
  module Restart
    extend Discordrb::Commands::CommandContainer
    command(:restart, description: "restarts the bot") do |event|
      break unless event.channel.id == DEBUGCHANNEL
      event.bot.send_message(DEBUGCHANNEL,"Restart issued.. :wrench:")
      event.bot.stop
      exit
    end
  end
end
