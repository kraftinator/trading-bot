 require './lib/exchanges/binance_factory.rb'

namespace :trading_pairs do
  
  desc 'List trading_pairs'
  task :list => :environment do
    
    ## Usage:
    ## rake trading_pairs:list
    
    puts "\nCURRENT TRADING PAIRS:"
    puts "-------------------"
    
    trading_pairs = TradingPair.all
    trading_pairs.each do |trading_pair|
      puts trading_pair.symbol
    end
    
    puts ""
    
  end
  
  desc 'Create trading pair'
  task :create => :environment do
    
    ## Usage:
    ## rake trading_pairs:create COIN=ETH TOKEN=ZRX PRECISION=8 MAX_PRICE=0.003
    
    puts "Creating trading_pair..."
    
    ## Get params
    coin = Coin.where( symbol: ENV["COIN"] ).first
    unless coin
      puts "ERROR: Coin #{ENV['COIN']} not found."
      exit
    end
    
    token = Token.where( symbol: ENV["TOKEN"] ).first
    unless token
      puts "ERROR: Token #{ENV['TOKEN']} not found."
      exit
    end
    
    ## Does trading_pair already exist?
    trading_pair = TradingPair.where( coin: coin, token: token ).first
    if trading_pair
      puts "ERROR: Trading Pair #{token.symbol}#{coin.symbol} already exists."
      exit
    end
    
    precision = ENV["PRECISION"]
    unless precision
      puts "ERROR: Precision not found."
      exit
    end
    
    max_price = ENV["MAX_PRICE"]
    unless max_price
      puts "ERROR: Max price not found."
      exit
    end
    max_price = BigDecimal.new( ENV["MAX_PRICE"] )
    
    ## Create trading_pair
    trading_pair = TradingPair.create( coin: coin, token: token, precision: precision, max_price: max_price )
    
    puts "SUCCESS: Trading pair #{trading_pair.symbol} created."
    
  end
  
  desc 'Update all trading pairs'
  task :update_all => :environment do
    BinanceFactory.update_trading_pairs
  end
 
end