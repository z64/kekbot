module KekBot
  module Keks
    extend Discordrb::Commands::CommandContainer
    command(:keks, description: "fetches your balance, or @user's balance") do |event, mention|

      #report our own keks if no @mention
      #pick up user if we have a @mention
      if mention.nil?
        mention = event.user.id.to_i
      else
        mention = event.message.mentions.at(0).id.to_i
      end

      #load user from $db, report if user is invalid or not registered.
      user = $db["users"][mention.to_s]
      if user.nil?
        event << "User does not exist, or hasn't `.register`ed yet. :x:"
        return
      end

      #report keks
      event << "#{event.bot.user(mention).mention}'s Dank Bank balance: **#{user['bank'].to_s} #{$db['currencyName']}**"
      event << "Stipend balance: **#{user['stipend'].to_s} #{$db['currencyName']}**"
      nil
    end
  end
end
