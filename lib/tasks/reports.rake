include ActionView::Helpers::DateHelper

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
    
    bots = Trader.where( trading_pair: trading_pair, active: true ).order( :sell_count ).reverse
    bots.each do |bot|
      results << "#{'%-8s' % bot.strategy.name}  #{'%4s' % bot.buy_count}  #{'%4s' % bot.sell_count}  #{'%.3f' % bot.percentage_range}  #{'%.8f' % bot.coin_amount}"
    end
    
    results.each { |r| puts r }
    puts "\n"
    
  end
  
  desc 'Revenue report by trading pair'
  task :revenue => :environment do
    
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
    results << "\nRevenue Report For #{trading_pair.symbol}\n\n"
    results << "#{'%-8s' % 'STRATEGY'}  #{'%4s' % 'BUYS'}  #{'%4s' % 'SELLS'}  #{'%4s' % 'PCT'}  #{'%5s' % 'TOTAL'}  #{'%20s' % 'PROFIT'}  #{'%25s' % 'LAST ACTION'}"
    results << "------------------------------------------------------------------------------------------------"
    
    ## Get current coint price
    if coin.symbol == 'ETH'
      ticker_name = 'ethereum'
    elsif
      coin.symbol == 'BTC'
      ticker_name == 'bitcoin'
    else
      puts "ERROR: Invalid coin symbol #{coin.symbol}."
    end

    puts "Getting coin price..."
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    response = HTTParty.get("https://api.etherscan.io/api?module=stats&action=ethprice")
    current_price = response.parsed_response['result']['ethusd'].to_f
    
    #response = HTTParty.get("https://api.coinmarketcap.com/v1/ticker/#{ticker_name}/?convert=USD")
    #current_price = response.parsed_response.first['price_usd'].to_f
    
    bots = Trader.where( trading_pair: trading_pair, active: true ).to_a.sort_by( &:coin_amount ).reverse
    coin_total = 0.0
    profit_total = 0.0
    bots.each do |bot|
      
      last_action_date = bot.show_last_fulfilled_order_date
      if last_action_date
        last_action_words = "#{time_ago_in_words( last_action_date ) } ago"
      else
        last_action_words = ''
      end
      
      results << "#{'%-8s' % bot.strategy.name}  #{'%4s' % bot.buy_count}  #{'%4s' % bot.sell_count}  #{'%.3f' % bot.percentage_range}  #{'%.8f' % bot.coin_amount}  $#{'%.2f' % bot.fiat_amount(current_price)}   #{'%.8f' % bot.profit }  $#{'%.2f' % bot.fiat_profit(current_price)}  #{'%14s' % last_action_words }"
      coin_total += bot.coin_amount
      profit_total += bot.profit
    end
    
    results << "\n"
    results << "TOTAL #{trading_pair.coin.symbol}: #{coin_total} ($#{ ( coin_total * current_price ).round(2) })"
    results << "PROFIT:    #{profit_total}  ($#{ ( profit_total * current_price ).round(2) })"
    
    results.each { |r| puts r }
    puts "\n"
    

    
  end
  
end