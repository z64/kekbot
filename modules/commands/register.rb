module KekBot
  module Register
    extend Discordrb::Commands::CommandContainer
    extend Tools
    command(:register, description: "registers new user") do |event|
      #grab user id
      id = event.user.id.to_s

      #check if user is already registered
      if !$db['users'][id].nil?
        event << "You are already registered, yung kek."
        return
      end

      #construct user
      $db['users'][id] = { "joined" => Time.now, "name" => event.user.name, "bank" => 10, "nickwallet" => false, "currencyReceived" => 0, "karma" => 0, "stipend" => 40, "collectibles" => [] }

      #welcome message
      event << "**Welcome to the KekNet, #{event.user.name}!**"
      event << "Use `.help` for a list of commands."
      event << "For more info: **https://github.com/z64/kekbot/blob/master/README.md**"

      save
      nil
    end
  end
end
