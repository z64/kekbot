module KekBot
  module Approve
    extend Discordrb::Commands::CommandContainer
    #approve a collectible
    command(:approve, min_args: 3, description: 'approves a submission, and sets a claim and unlock value, as a delta of the total amount of currency traded to date', usage: '.approve [description] [value] [unlock]') do |event, *message|
      break unless event.channel.id == DEBUGCHANNEL

      #setup
      unlock = message.pop.to_i
      value = message.pop.to_i
      message = message.join(' ')
      collectible = getCollectible(message)
      author = event.bot.user(collectible['data']['author'])

      #check we spelt it right. let's be real, here
      if collectible.nil?
        event << "Collectible `#{message}` not found. :("
        return
      end

      #check that a submission isn't already approved
      if (collectible['data']['unlock'] != 0) || (!collectible['data']['owner'].nil?) || (collectible['data']['visible']) || (collectible['data']['value'] != 0)
        event << "This collectible is already on the market."
        return
      end

      #configure collectible to be unlocked
      collectible['data']['unlock'] = $db['stats']['currencyTraded'] + unlock
      collectible['data']['value'] = value

      #stats
      $db['stats']['submissionsApproved'] += 1

      #notifications
      event << "`#{message}` approved!"
      event << "This collectible will be unlocked once #{unlock} more #{$db['currencyName']} are traded. (current: `#{$db['stats']['currencyTraded']}`)"

      #let the submitted know we accepted it.
      author.pm("***Rejoice, mortal!*** Your submission `#{message}` has been approved. Thank you!")
      save
      nil
    end
  end
end
