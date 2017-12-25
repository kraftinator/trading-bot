namespace :reports do
  
  desc 'Print report by trading pair'
  task :basic => :environment do
    
    ## Usage:
    ## rake reports:basic COIN=ETH TOKEN=REQ
    
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
    
    results = []
    results << ""
    results << trading_pair.symbol
    results << "--------------------------------------------"
    bots = Trader.order( :sell_count ).reverse
    bots.each do |bot|
      results << "#{bot.strategy.name}  #{bot.buy_count}  #{bot.sell_count}  #{bot.percentage_range}" 
    end
    results << ""
    
    ## Print results
    results.each { |r| puts r }
    
  end
  
end