module KekBot
  module Reject
    extend Discordrb::Commands::CommandContainer
    extend Tools
    command(:reject, min_args: 1, description: "rejects a submission", usage: ".reject [description] --reason [optional reason]") do |event, *message|
      break unless event.channel.id == DEBUGCHANNEL

      #setup
      message = message.join(' ')
      message = message.split('--reason').map(&:strip)
      collectible = message[0]
      reason = message[1]
      collectible = getCollectible(collectible)
      author = event.bot.user(collectible['data']['author'])

      #check we spelt it right. let's be real, here
      if collectible.nil?
        event << "Collectible `#{message}` not found. :("
        return
      end

      #don't let mods reject something that already has an owner.
      if !collectible['data']['owner'].nil?
        event << "This collectible already has an owner."
        event << "You can't reject it."
      end

      #let the author know we rejected their submission, and why if a reason was supplied
      author.pm("Your submission `#{collectible['data']['description']}` has been rejected.")
      if reason.nil?
        author.pm("There was no reason supplied by the moderators. Sorry! :frowning:")
      else
        author.pm("It was rejected by the moderation with the following message: `#{reason}`")
      end

      #notification
      event << "Rejected submission `#{collectible['data']['description']}`."

      #delete the submission
      $db["collectibles"].delete(collectible['id'])

      #stats
      $db['stats']['submissionsRejected'] += 1
      save
      nil
    end
  end
end
