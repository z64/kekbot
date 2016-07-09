module KekBot
  module Loaddb
  	extend Discordrb::Commands::CommandContainer
    command(:loaddb, description: "reloads database") do |event|
      break unless event.channel.id == DEBUGCHANNEL
      file = File.read('kekdb.json')
      $db = JSON.parse(file)
      event << "Loaded database from **#{$db['timestamp']}** :computer:\n"
    end
  end
end
