module KekBot
  module Getdb
    extend Discordrb::Commands::CommandContainer
    command(:getdb, description: "uploads the current databse file") do |event|
      break unless event.channel.id == DEBUGCHANNEL
      file = File.open('kekdb.json')
      event.channel.send_file(file)
    end
  end
end
