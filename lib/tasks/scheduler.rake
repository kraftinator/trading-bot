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
  task :process => :environment do
    BotTrader.process_all
  end
  
end