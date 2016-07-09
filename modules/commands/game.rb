module KekBot
  module Game
  	extend Discordrb::Commands::CommandContainer
    command(:game, description: "sets bot game") do |event, *game|
      break unless event.channel.id == DEBUGCHANNEL
      event.bot.game = game.join(' ')
      nil
    end
  end
end
