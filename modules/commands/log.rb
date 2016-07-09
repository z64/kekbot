module KekBot
  module Log
    extend Discordrb::Commands::CommandContainer
    command(:log, min_args: 1, description:"gets n many rev logs") do |event, number|
      cmd = "git log --pretty=format:\"%h - %an, %ar : %s\" -n #{number}"
      log = `#{cmd}`
      cmd = "git branch"
      branch = `#{cmd}`
      event <<"Current branch: `#{branch}`"
      event << "```#{log}```"
      event << "**https://github.com/z64/kekbot**"
    end
  end
end
