namespace :bots do
  
  desc 'Create bot'
  task :create => :environment do
    
    ## Usage:
    ## rake bots:create COIN=ETH TOKEN=REQ COIN_QTY=0.05 PERCENTAGE_RANGE=0.05 WAIT_PERIOD=1440 STRATEGY=ALPHA
    
    puts "Creating bot..."
    
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
    
    trading_pair = TradingPair.where( coin: coin, token: token ).first
    unless trading_pair
      puts "ERROR: Trading Pair #{token.symbol}#{coin.symbol} not found."
      exit
    end
    
    strategy = Strategy.where( name: ENV["STRATEGY"] ).first
    unless strategy
      puts "ERROR: Strategy #{strategy} not found."
      exit
    end
    
    coin_qty = BigDecimal.new( ENV["COIN_QTY"] )
    if coin_qty > 1
      puts "ERROR: Coin quantity cannot be 1 or higher. You can override this restriction in the Rails console."
      exit
    end
    
    percentage_range = BigDecimal.new( ENV["PERCENTAGE_RANGE"] )
    if percentage_range >= 1
      puts "ERROR: Percentage range cannot be 1 or higher."
      exit
    end
    
    wait_period = ENV["WAIT_PERIOD"].to_i
    if wait_period < 60
      puts "ERROR: Wait period cannot be less than 60 minutes."
      exit
    end
    
    ## Params validated. Create bot.
    trader = Trader.create( trading_pair: trading_pair,
                            strategy: strategy, 
                            coin_qty: coin_qty,
                            original_coin_qty: coin_qty,
                            percentage_range: percentage_range,
                            wait_period: wait_period,
                            active: true )
    
    puts "SUCCES: Bot Created! Symbol = #{trader.trading_pair.symbol}, Initial Qty = #{trader.coin_qty.to_s} #{trader.trading_pair.coin.symbol}, Percent = #{trader.percentage_range.to_s}, Wait Period = #{trader.wait_period} minutes, Strategy = #{trader.strategy.name}."
    
  end
    
end