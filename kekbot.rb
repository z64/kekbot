require 'discordrb'
require 'json'
require 'yaml'
require 'digest/sha1'

bot = Discordrb::Commands::CommandBot.new token: ARGV[0], application_id: 185442396119629824, prefix: '.'

puts "This bot's invite URL is #{bot.invite_url}."

#global things
$db = Hash.new
devChannel = 184597857414676480
version = "v1.0"

bot.ready do |event|

  file = File.read('kekdb.json')
  $db = JSON.parse(file)

  message = ""

  message << "Loaded database from **" + File.atime("kekdb.json") + "** :file_folder: \n"

  cmd = "git log --pretty=\"%h\" -n 1"
  rev = `#{cmd}`
  event.bot.game = "#{version} [#{rev.strip}]"

  cmd = "git log -n 1"
  log = `#{cmd}`

  cmd = "git branch | grep \"*\""
  branch = `#{cmd}`

  message << "**Current Revision**\n```branch: #{branch}\n#{log}```\n"
  message << "**Bot ready!** :raised_hand:"

  bot.send_message(devChannel, message)

  bot.send_message(devChannel, "**Active servers** :computer:")
  bot.servers.each do |x|
    registered = x[1].members.collect do |m|
      true unless $db['users'][m.id.to_s].nil?
    end
    registered = registered.compact.length
    bot.send_message(devChannel, "```name: #{x[1].name}\nowner: #{x[1].owner.username}\nregistered members: #{registered} / #{x[1].member_count}```")
    sleep 0.5
  end

end

# strip users that are unreachable to the bot.
bot.heartbeat do
  $db['collectibles'].each do |rare|
    break unless rare['owner'].nil?
    $db["users"].delete(rare['owner'].to_s) unless bot.user(rare['owner']).nil?
    save
  end
end

#restart bot
bot.command(:restart, description: "restarts the bot") do |event|
  break unless event.channel.id == devChannel

  bot.send_message(devChannel,"Restart issued.. :wrench:")
  bot.stop
  exit

end

bot.command(:game, description: "sets bot game") do |event, *game|
  break unless event.channel.id == devChannel

  event.bot.game = game.join(' ')
  nil

end

#DATABASE
#load $db
bot.command(:loaddb, description: "reloads database") do |event|
  break unless event.channel.id == devChannel

  file = File.read('kekdb.json')
  $db = JSON.parse(file)

  event << "Loaded database from **#{$db['timestamp']}** :computer:\n"

end

#rev - get latest rev + patchnote
bot.command(:rev, description:"gets bot's HEAD revision") do |event|

  cmd = "git log -n 1"
  log = `#{cmd}`

  cmd = "git branch"
  branch = `#{cmd}`

  event << "Current branch:\n`#{branch}`"
  event << "```#{log}```"
  event << "**https://github.com/z64/kekbot**"

end

bot.command(:log, min_args: 1, description: "gets n many rev logs") do |event, number|

  cmd = %q(git log --pretty=format:\"%h - %an, %ar : %s\" -n ) + number
  log = `#{cmd}`

  cmd = "git branch"
  branch = `#{cmd}`

  event << "Current branch: `#{branch}`"
  event << "```#{log}```"
  event << "**https://github.com/z64/kekbot**"

end

bot.command(:getdb, description: "uploads the current database file") do |event|
  break unless event.channel.id == devChannel

  file = File.open('kekdb.json')
  event.channel.send_file(file)

end

#save $db
bot.command(:save, description: "force database save") do |event|
  break unless event.channel.id == devChannel

  save

  event << "**You have saved the keks..** :pray:"

end

bot.command(:register, description: "registers new user") do |event|

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

#KEKS
#get keks
bot.command(:keks, description: "fetches your balance, or @user's balance") do |event, mention|

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
  event << "#{bot.user(mention).mention}'s Dank Bank balance: **#{user['bank'].to_s} #{$db['currencyName']}**"
  event << "Stipend balance: **#{user['stipend'].to_s} #{$db['currencyName']}**"

  nil
end

#set keks
bot.command(:setkeks, min_args: 3, description: "sets @user's kek and stipend balance") do |event, mention, bank, stipend|
  break unless event.channel.id == devChannel

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

#give keks
bot.command(:give, min_args: 2,  description: "give currency") do |event, to, value|

  #cast early because this is what ruby wants apparently
  #codeCommentsAt1am
  value = value.to_i

  #pick up user
  fromUser = $db["users"][event.user.id.to_s]

  #return if invalid user
  if fromUser.nil?
    event << "User does not exist, or hasn't `.register`ed yet. :x:"
    return
  end

  #handle negative values
  if(value < 0)
    event << "http://i.imgur.com/J1HocUj.png"
    return
  end

  #check if they have enough first
  if (fromUser["stipend"] - value) < 0
    event << "You do not have enough #{$db["currencyName"]} to make this transaction. :disappointed_relieved:"
    return
  end

  #flattery won't get you very far with KekBot
  if bot.parse_mention(to).id == event.bot.profile.id
    event << "Wh-... wha.. #{event.user.on(event.server).display_name}-senpai...*!*"
    event << "http://i.imgur.com/nxMsRS5.png"
    return
  end

  #pick up user to receive currency
  toUser = $db["users"][event.message.mentions.at(0).id.to_s]

  #check that they exist
  if toUser.nil?
    event << "User does not exist, or hasn't `.register`ed yet. :x:"
    return
  end

  #you can't give keks to yourself
  if fromUser == toUser
    event << "https://media.giphy.com/media/yidUzkciDTniZ7OHte/giphy.gif"
    return
  end

  #transfer keks
  fromUser["stipend"] -= value
  toUser["bank"] += value

  #update user stats
  toUser["currencyReceived"] += value
  toUser["karma"] += 1

  #update server stats
  $db['stats']['currencyTraded'] += value

  #notification
  event << "**#{event.user.on(event.server).display_name}** awarded **#{event.message.mentions.at(0).on(event.server).display_name}** with **#{value.to_s} #{$db["currencyName"]}** :joy: :ok_hand: :fire:"

  #unlock
  $db['collectibles'].each do |id, data|

    #check if collectible is hidden, and we've passed its
    if ($db['stats']['currencyTraded'] >= data['unlock']) & (data['unlock'] != 0) & !data['visible']

      #make the collectible available
      data['visible'] = true

      #announce
      event << "***Collectible Unlocked:*** `#{data['description']}` :confetti_ball:"
      event << "Use `.claim #{data["description"]}` to claim this #{$db["collectiblesName"]} for: **#{data["value"].to_s} #{$db["currencyName"]}!**"
      event << data['url']

      #announce in devChannel
      event.bot.send_message(devChannel, "Collectible `#{data['description']}` unlocked by `#{event.user.name} (#{event.user.id})`!")

    end

  end

  save
  nil
end

bot.command(:setstipend, min_args: 1, description: "sets all users stipend values") do |event, value|
  break unless event.channel.id == devChannel

  #get integer
  value = value.to_i

  #update all users
  $db["users"].each do |id, data|
    data["stipend"] = value
  end

  #notification
  event << "All stipends set to `#{value.to_s}`"

  save
  nil
end

#COLLECTIBLES
#inspect a collectible
bot.command(:show, min_args: 1, description: "displays a rare, or tells you who owns it", usage: ".show [description]") do |event, *description|

  #stitch args together
  description = description.join(' ')

  #get user
  user = $db["users"][event.user.id.to_s]

  # look for our collectible, and do checks
  collectible = getCollectible(description)

  # check collectible doesn't exist, or is hidden
  if collectible.nil? | !collectible['data']['visible']
    event << "The #{$db["collectiblesName"]} `#{description}` doesn't exist, or isn't in your inventory."
    return
  end

  # output the collectible if its ours
  if !user['collectibles'].grep(collectible['id']).empty?
    event << "#{event.user.mention}\'s `#{description}`: "
    event << collectible['data']['url']
    return
  end

  # don't show it if it exists, but is claimed by someone else
  event << "`#{description}` is a claimed #{$db["collectiblesName"]}! :eyes:" ; return unless !collectible['data']['owner'].nil?

  #its unclaimed at this point - tell the user how to claim it
  event << "`#{description}` is an unclaimed #{$db["collectiblesName"]}! :eyes:"
  event << "Use `.claim #{collectible["data"]["description"]}` to claim this #{$db["collectiblesName"]} for: **#{collectible["data"]["value"].to_s} #{$db["currencyName"]}!**"
  event << collectible["data"]['url']

end

#list collectibles
bot.command(:rares, description: "list what rares you own") do |event|

  #get user
  user = $db["users"][event.user.id.to_s]

  #init list with intro text
  list = "#{event.user.mention}\'s `#{user["collectibles"].length.to_s}` #{$db["collectiblesName"]}s:\n\n"

  #buffer our output in case we go over 2k characters
  user["collectibles"].each do |x|

    #output string
    addition = "`#{$db["collectibles"][x]["description"]}`"

    #if our next addition will go over our 2000 char buffer, spit out the list and clear the buffer
    if (addition.length + list.length) > 2000
      event.respond(list)
      list = ""
    end

    #add next addition
    list << "#{addition}  "

  end

  #output list / end of list
  event.respond(list)

  #some extra help text
  event << "\nInspect a #{$db["collectiblesName"]} in your inventory with `.show [description]`."

end

#list all collectibles
bot.command(:catalog, description: "lists all unclaimed rares") do |event|

  #intro text
  message = "**Unclaimed #{$db["collectiblesName"]}s**\nClaim any #{$db["collectiblesName"]} in the list below with `.claim [description]`.\n\n"

  #buffer our output in case we go over 2k characters
  $db["collectibles"].each do |id, data|

    #if next addition goes over the 2k buffer, spit it out and clear the buffer
    if (message.length + data["description"].length) > 2000
      event.respond(message)
      message = ''
    end

    #add next collectible to message if its unclaimed
    if (!data['owner'] & data['visible']) then message << "`#{data["description"]} (#{data["value"]})`  " end

  end

  #output list / end of list
  event.respond(message)

end

#add collectibles
bot.command(:submit, min_args: 2, description: "adds a rare to the $db", usage: ".submit [url] [description]") do |event, url, *description|

  #stitch together description splat
  description = description.join(' ')

  #for the time being, only allow lowercase submissions
  description = description.downcase

  $db['collectibles'].each do |key, data|
    if data['url'] == url
      event << "This collectible already exists under a different name!"
    end
    if data['description'] == description
      event << "A collectible already exists with this description."
    end
  end

  #write new collectible
  $db['collectibles'][Digest::SHA1.hexdigest(url)] = { "description" => description, "timestamp"=> Time.now, "author" => event.user.id, "owner" => nil, "url" => url, "visible" => false, "unlock" => 0, "value" => 0 }

  #output success
  event << "**Thank you #{event.user.mention}!**"
  event << "Submitted rare: `#{description}`"

  #let admins know a collectible was submitted
  if event.channel.id != devChannel
    event.bot.send_message(devChannel, "`#{event.user.name} [#{event.user.id}]` submitted rare: `#{description}` :smile:\n#{url}")
  end

  #stats
  $db['stats']['submissions'] += 1

  save
  nil
end

#approve a collectible
bot.command(:approve, min_args: 3, description: 'approves a submission, and sets a claim and unlock value, as a delta of the total amount of currency traded to date', usage: '.approve [description] [value] [unlock]') do |event, *message|
  break unless event.channel.id == devChannel

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

  #we did it reddit
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

#rejection
bot.command(:reject, min_args: 1, description: "rejects a submission", usage: ".reject [description] --reason [optional reason]") do |event, *message|
  break unless event.channel.id == devChannel

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

#claim collectible
bot.command(:claim, min_args: 1, description: "claims an unclaimed rare", usage: ".claim [description]") do |event, *description|

  #stitch together description splat
  description = description.join(' ')

  #grab user
  user = $db['users'][event.user.id.to_s]

  #select collectible
  collectible = getCollectible(description)

  #error if collectible doesn't exist
  if (collectible.nil? | !collectible['data']['visible'])
    event << "This rare does not exist.. :eyes:"
    return
  end

  #check if its already claimed
  if !collectible['data']['owner'].nil?
    event << "`#{description}` is already claimed.. :eyes:"
    return
  end

  #make sure we can afford it
  if user['bank'] < collectible['data']['value']
    event << "Not enough **#{$db["currencyName"]}** in your **Dank Bank**.. :eyes:"
    return
  end

  #its unclaimed and we can afford it
  #perform transaction
  user['collectibles'] << collectible['id']
  user['bank'] -= collectible['data']['value']
  collectible['data']['owner'] = event.user.id
  save

  #output success
  event << "`#{description}` has been added to your `.rares`! :money_with_wings:"

end

bot.command(:sell, min_args: 3, description: "create a sale", usage: ".sell [description] @user [offer]") do |event, *sale|

  #setup
  amount = sale.pop.to_i
  sale.pop #pop off mention
  description = sale.join(' ')
  buyer = event.message.mentions.at(0)
  seller = event.user
  buyer_db = $db['users'][buyer.id.to_s]
  seller_db = $db['users'][seller.id.to_s]
  collectible = getCollectible(description)

  #handle negative values
  if(amount < 0)
    event << "http://i.imgur.com/J1HocUj.png"
    return
  end

  #check collectible exists
  if collectible.nil?
    event << "This #{$db["collectiblesName"]} does not exist.. :eyes:"
    return
  end

  #check that you own what you want to sell
  if collectible['data']['owner'] != seller.id
    event << "You don't have this #{$db["collectiblesName"]}.. :eyes:"
    return
  end

  #check buyer can afford
  if amount > buyer_db['bank']
    event << "#{buyer.on(event.server).display_name} can not afford that sale.. :eyes:"
    return
  end

  #process sale
  event << "#{seller.on(event.server).display_name} wants to sell `#{description}` to #{buyer.on(event.server).display_name} for #{amount} #{$db["currencyName"]}! :incoming_envelope:"
  event << "#{buyer.mention}, type `accept` or `reject`"

  #await for accept / reject response
  buyer.await(:sale) do |subevent|

    if subevent.message.content == "accept"

      #users balance could have changed since sale created - double check we can afford it
      if amount > buyer_db["bank"]

        subevent.respond("#{buyer.on(event.server).display_name} can no longer afford that sale.. :eyes:")

      else #complete sale..

        #swap collectible between users
        seller_db["collectibles"].delete(collectible['id'])
        buyer_db["collectibles"] << collectible['id']
        collectible['owner'] = buyer.id

        #process currency transaction
        buyer_db["bank"] -= amount
        seller_db["bank"] += amount

        #output message
        subevent.respond("#{buyer.on(event.server).display_name} accepted your offer, #{event.user.mention}!")

        #stats
        $db['stats']['sales'] += 1
        $db['stats']['salesValue'] += amount

        save

      end

      #sale complete - destroy await
      true

    elsif subevent.message.content == "reject"

      subevent.respond("#{buyer.on(event.server).display_name} has rejected your offer, #{event.user.mention} :x:")

      #sale rejected - destroy await
      true

    else

      #message was something else; ignore it and keep await alive
      false

    end

  end
  nil
end

bot.command(:trade, description: "trade collectibles with other users", usage: ".trade @user [yourCollectible] / [theirCollectible]") do |event, *trade|

  #setup
  trade.shift #drop mention

  user_a = event.user
  user_a_db = $db['users'][user_a.id.to_s]

  user_b = event.message.mentions.at(0)
  user_b_db = $db['users'][user_b.id.to_s]
  trade = trade.join(' ').split("\s/\s").slice(0..1)

  #check that collectibles exist
  collectible_a = getCollectible(trade[0])
  if collectible_a.nil?
    event << "#{$db["collectiblesName"]} `#{trade[0]}` not found."
    return
  end

  collectible_b = getCollectible(trade[1])
  if collectible_b.nil?
    event << "#{$db["collectiblesName"]} `#{trade[1]}` not found."
    return
  end

  #check that each user owns the specified collectibles
  if user_a_db["collectibles"].grep(collectible_a['id']).empty?
    event << "You don't own that #{$db["collectiblesName"]}..!"
    return
  end

  if user_b_db["collectibles"].grep(collectible_b['id']).empty?
    event << "#{user_b_db} doesn't own that #{$db["collectiblesName"]}"
    return
  end

  event << "#{user_a.on(event.server).display_name} wants to trade his `#{collectible_a["data"]["description"]}` for your `#{collectible_b['data']["description"]}` #{event.message.mentions.at(0).mention}!"
  event << "Respond with `accept` or `reject` to complete the trade."

  event.message.mentions.at(0).await(:trade) do |subevent|

    if subevent.message.content == "accept"

      #perform the trade
      user_a_db["collectibles"].delete(collectible_a['id'])
      user_a_db["collectibles"] << collectible_b['id']

      user_b_db["collectibles"].delete(collectible_b['id'])
      user_b_db["collectibles"] << collectible_a['id']

      collectible_a['owner'] = user_b.id
      collectible_b['owner'] = user_a.id

      subevent.respond("Trade complete! :blush: :heart:")

      #stats
      $db['stats']['trades'] += 1

      save
      true

    elsif subevent.message.content == "reject"

      subevent.respond("#{user_b.on(event.server).display_name} has rejected your offer, #{event.user.mention} :x:")

      true

    else

      false

    end
  end
  nil
end

bot.command(:eval, help_available: false) do |event, *code|
  break unless event.user.id == 120571255635181568

  begin
    eval code.join(' ')
  rescue
    "An error occured 😞"
  end
end

#FUNCTIONS
def save
  $db['timestamp'] = Time.now.to_s
  file = File.open("kekdb.json", "w")
  file.write(JSON.pretty_generate($db))
end

def getCollectible(description)
  $db['collectibles'].each do |id, data|
    return { "id" => id, "data" => data } if data['description'] == description
  end
  return nil
end

def parse(seperator, input)
  input = input.prepend("#{seperator}default ")
  output = Hash.new
  input.split(seperator).drop(1).map do |x|
    x = x.split(' ')
    arg = x.shift
    puts content = x.join(' ')
    output[arg] = content
  end
  return output
end

bot.run
