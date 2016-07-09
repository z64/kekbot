module KekBot
  module Eval
    extend Discordrb::Commands::CommandContainer
    command(:eval, help_available: false) do |event, *code|
      break unless event.user.id == 120571255635181568
      begin
        eval code.join(' ')
      rescue => e
        "An error occured 😞 ```#{e}```"
      end
    end
  end
end
