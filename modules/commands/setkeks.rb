module KekBot
  module Setkeks
    extend Discordrb::Commands::CommandContainer
    extend Tools
    command(:setkeks, min_args: 3, description: "sets @user's kek and stipend balance") do |event, mention, bank, stipend|
      break unless event.channel.id == DEBUGCHANNEL

      #get integers
      bank = bank.to_i
      stipend = stipend.to_i

      #update $db with requested values
      user = event.bot.parse_mention(mention).id.to_s
      $db['users'][user]['bank'] = bank
      $db['users'][user]['stipend'] = stipend

      #notification
      event << "Oh, senpai.. updated! :wink:"
      save
      nil
    end
  end
end
