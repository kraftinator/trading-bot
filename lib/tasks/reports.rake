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
    results << "\nBasic Report For #{trading_pair.symbol}\n\n"
    results << "#{'%-8s' % 'STRATEGY'}  #{'%4s' % 'BUYS'}  #{'%4s' % 'SELLS'}  #{'%4s' % 'PCT'}  #{'%7s' % 'TOTAL ' + trading_pair.coin.symbol}"
    results << "--------------------------------------------"
    
    bots = Trader.where( active: true ).order( :sell_count ).reverse
    bots.each do |bot|
      results << "#{'%-8s' % bot.strategy.name}  #{'%4s' % bot.buy_count}  #{'%4s' % bot.sell_count}  #{'%.3f' % bot.percentage_range}  #{'%.8f' % bot.coin_qty}" 
    end
    
    results.each { |r| puts r }
    puts "\n"
    
  end
  
end