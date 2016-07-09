module KekBot
  module Rev
  	extend Discordrb::Commands::CommandContainer
    command(:rev, description:"gets bot's HEAD revision") do |event|

      cmd = "git log -n 1"
      log = `#{cmd}`

      cmd = "git branch"
      branch = `#{cmd}`

      event <<"Current branch:\n`#{branch}`"
      event << "```#{log}```"
      event << "**https://github.com/z64/kekbot**"

    end
  end
end
