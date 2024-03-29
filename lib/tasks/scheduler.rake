require './lib/bot_trader.rb' 

namespace :scheduler do
  
  desc 'Run bots by trading pair'
  task :process => :environment do
    
    ## Validate parameters
    trading_pair_str = ENV["TRADING_PAIR"]
    unless trading_pair_str
      puts "ERROR: Parameter TRADING_PAIR not found."
      exit
    end
    
    symbols = trading_pair_str.split( '_' )
    if symbols.size < 2 or symbols.size > 2
      puts "ERROR: Parameter TRADING_PAIR is invalid."
      exit
    end
    
    token = Token.where( symbol: symbols[0] ).first
    unless token
      puts "ERROR: Token #{symbols[0]} not found."
      exit
    end
    
    coin = Coin.where( symbol: symbols[1] ).first
    unless coin
      puts "ERROR: Coin #{symbols[1]} not found."
      exit
    end
    
    trading_pair = TradingPair.where( coin: coin, token: token ).first
    unless trading_pair
      puts "ERROR: Trading Pair #{token.symbol}#{coin.symbol} not found."
      exit
    end
    
    #############################################
    ## Parameters validated. Run bots.
    #############################################
    BotTrader.process( trading_pair )
        
  end
  
  desc 'Run all bots'
  task :process_all => :environment do
    #BotTrader.process_all
  end
  
  desc 'Run all bots secret method'
  task :process_all_secret => :environment do
    BotTrader.process_all
  end
  
  desc 'Run bots by user'
  task :process_user => :environment do
    BotTrader.process_user( User.first )
  end
  
  desc 'Run jobs to process campaigns'
  task :process_campaigns => :environment do
    BotTrader.process_campaigns
  end
  
  desc 'Run bots by campaign'
  task :process_exchange => :environment do
    
    ## Validate parameters
    exchange_id = ENV["EXCHANGE_ID"]
    unless exchange_id
      puts "ERROR: Parameter EXCHANGE_ID not found."
      exit
    end
    
    exchange = Exchange.find_by( id: exchange_id )
    unless exchange
      puts "ERROR: Invalid EXCHANGE_ID - #{exchange_id}"
      exit
    end
    
    puts "Process exchange #{exchange.name}"
    
    trading_pairs = exchange.trading_pairs
    trading_pairs.each do |trading_pair|
      campaigns = trading_pair.campaigns.active
      campaigns.each do |campaign|
        puts "Processing campaign #{campaign.trading_pair_display_name}"
        BotTrader.process_campaign( campaign )
      end
    end
    
  end
  
  desc 'Run Binance bots'
  task :process_binance => :environment do
    exchange = Exchange.where( name: 'Binance' ).first
    trading_pairs = exchange.trading_pairs
    trading_pairs.each do |trading_pair|
      campaigns = trading_pair.campaigns.active
      campaigns.each do |campaign|
        puts "Processing campaign #{campaign.trading_pair_display_name}"
        BotTrader.process_campaign( campaign )
      end
    end
  end
  
  desc 'Run Coinbase bots'
  task :process_coinbase => :environment do
    exchange = Exchange.where( name: 'Coinbase' ).first
    trading_pairs = exchange.trading_pairs
    trading_pairs.each do |trading_pair|
      campaigns = trading_pair.campaigns.active
      campaigns.each do |campaign|
        puts "Processing campaign #{campaign.trading_pair_display_name}"
        BotTrader.process_campaign( campaign )
      end
    end
  end
  
  desc 'Run specific bot'
  task :process_trader => :environment do
    
    ## Validate parameters
    trader_id = ENV["TRADER_ID"]
    unless trader_id
      puts "ERROR: Parameter TRADER_ID not found."
      exit
    end
    
    trader = Trader.find( trader_id )
    unless trader
      puts "ERROR: Invalid TRADER_ID - #{trader_id}"
      exit
    end
        
    BotTrader.process_trader( trader )
    
  end
  
  desc 'Summarize campaign coin totals'
  task :process_campaign_coin_totals => :environment do
    users = User.all
    users.each do |user|
      campaigns = user.campaigns.active
      campaigns.each do |campaign|
        CampaignCoinTotalWorker.perform_async( campaign.id )
      end
    end
  end
  
  desc 'Summarize campaign coin totals without sidekiq'
  task :process_campaign_coin_totals_without_sidekiq => :environment do
    users = User.all
    users.each do |user|
      campaigns = user.campaigns.active
      campaigns.each do |campaign|
        campaign.load_stats
      end
    end
  end
  
  desc 'Clear old records from database'
  task :process_clear_records => :environment do
    ClearRecordsWorker.perform_async
  end

end