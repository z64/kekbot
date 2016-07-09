require 'discordrb'
require 'digest/sha1'
require 'json'
require 'yaml'

#config file
CONFIG = YAML.load(File.read('config.yaml'))

#global db hash
$db = Hash.new

#check that we're configured properly
CONFIG.each do |key, value|
  if value.nil?
    puts "config.yaml: #{key} not supplied!"
    puts "Please completely fill out the config.yaml template and try again."
    exit
  elsif
    puts "config.yaml: Found #{key}: #{value}"
  end
end

module KekBot

  #configuration
  VERSION      = CONFIG['version']
  APPID        = CONFIG['appid']
  TOKEN        = CONFIG['token']
  DEBUGCHANNEL = CONFIG['debugChannel']
  OWNER        = CONFIG['owner']
  PREFIX       = CONFIG['prefix']
  BOT_ID       = CONFIG['bot']

  # require modules
  Dir['modules/*.rb'].each          { |r| require_relative r ; puts "Loaded rb: #{r}" }
  Dir['modules/commands/*.rb'].each { |r| require_relative r ; puts "Loaded rb: #{r}" }
  Dir['modules/events/*.rb'].each   { |r| require_relative r ; puts "Loaded rb: #{r}" }
  modules = [
    Approve,
    Catalog,
    Claim,
    Eval,
    Game,
    Getdb,
    Give,
    Keks,
    Loaddb,
    Log,
    Rares,
    Ready,
    Register,
    Reject,
    Restart,
    Rev,
    Save,
    Sell,
    Setkeks,
    Setstipend,
    Show,
    Submit,
    Trade
  ]

  # setup bot
  bot = Discordrb::Commands::CommandBot.new(token: TOKEN, application_id: APPID, prefix: PREFIX)
  modules.each { |m| bot.include! m }

  bot.run
end
