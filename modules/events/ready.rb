module KekBot
  module Ready
    extend Discordrb::EventContainer
    ready do |event|
      file = File.read('kekdb.json')
      $db = JSON.parse(file)

      message = ""
      message << "Loaded database from **" + $db['timestamp'] + "** :file_folder: \n"

      cmd = "git log --pretty=\"%h\" -n 1"
      rev = `#{cmd}`
      event.bot.game = "#{VERSION} [#{rev.strip}]"

      cmd = "git log -n 1"
      log = `#{cmd}`

      cmd = "git branch | grep \"*\""
      branch = `#{cmd}`

      message << "**Current Revision**\n```branch: #{branch}\n#{log}```\n"
      message << "**Bot ready!** :raised_hand:"

      event.bot.send_message(DEBUGCHANNEL, message)
    end
  end
end
