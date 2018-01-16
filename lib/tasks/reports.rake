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
    results << "#{'%-3s' % 'ID'}  #{'%-8s' % 'STRATEGY'}  #{'%4s' % 'BUYS'}  #{'%4s' % 'SELLS'}  #{'%3s' % 'BUY%'}   #{'%3s' % 'SELL%'}  #{'%3s' % 'CLG%'}  #{'%7s' % 'TOTAL ' + trading_pair.coin.symbol}  #{'%21s' % 'LAST ACTION'}"
    results << "--------------------------------------------------------------------------------------"
    
    bots = Trader.where( trading_pair: trading_pair, active: true ).order( :sell_count ).reverse
    bots.each do |bot|
      
      last_action_date = bot.show_last_fulfilled_order_date
      if last_action_date
        last_action_words = "#{time_ago_in_words( last_action_date ) } ago"
      else
        last_action_words = ''
      end
      
      results << "#{'%-3s' % bot.id.to_s}  #{'%-8s' % bot.strategy.name}  #{'%4s' % bot.buy_count}  #{'%5s' % bot.sell_count}  #{'%.3f' % bot.buy_pct}  #{'%.3f' % bot.sell_pct}  #{'%.3f' % bot.ceiling_pct}  #{'%.8f' % bot.coin_amount}  #{'%20s' % last_action_words }"
      
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
    results << "#{'%-3s' % 'ID'}  #{'%-6s' % 'STRATEGY'}  #{'%3s' % 'BUY%'}   #{'%3s' % 'SELL%'}  #{'%3s' % 'CLG%'}  #{'%6s' % 'SELLS'}  #{'%5s' % 'TOTAL' }  #{'%21s' % 'PROFIT'}  #{'%35s' % 'LAST ACTION'}"
    results << "------------------------------------------------------------------------------------------------------------"
    
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
    
    #current_price = 1100
    
    #response = HTTParty.get("https://api.coinmarketcap.com/v1/ticker/#{ticker_name}/?convert=USD")
    #current_price = response.parsed_response.first['price_usd'].to_f
    
    bots = Trader.where( trading_pair: trading_pair, active: true ).to_a.sort_by( &:coin_amount ).reverse
    #bots = Trader.where( trading_pair: trading_pair ).to_a.sort_by( &:coin_amount ).reverse
    coin_total = 0.0
    profit_total = 0.0
    original_total = 0.0
    bots.each do |bot|
      
      last_action_date = bot.show_last_fulfilled_order_date
      if last_action_date
        last_action_words = "#{time_ago_in_words( last_action_date ) } ago"
      else
        last_action_words = ''
      end
      
      results << "#{'%-3s' % bot.id.to_s}  #{'%-8s' % bot.strategy.name}  #{'%.3f' % bot.buy_pct}  #{'%.3f' % bot.sell_pct}  #{'%.3f' % bot.ceiling_pct}  #{'%5s' % bot.sell_count}  #{'%.8f' % bot.coin_amount}  #{'%7s' % bot.formatted_fiat_amount(current_price)}   #{'%.8f' % bot.profit }  #{'%7s' % bot.formatted_fiat_profit(current_price)}  #{'%22s' % last_action_words }"
      coin_total += bot.coin_amount
      profit_total += bot.profit
      original_total += bot.original_coin_qty
    end
    
    #results << "\n"
    #results << "TOTAL #{trading_pair.coin.symbol}: #{coin_total} ($#{ ( coin_total * current_price ).round(2) })"
    #results << "PROFIT:    #{profit_total}  ($#{ ( profit_total * current_price ).round(2) })"

    precision = trading_pair.precision

    results << "\n"
    results << "AMOUNT INVESTED: #{'%.8f' % original_total}  (#{'%7s' % formatted_currency(original_total * current_price)})" 
    results << "   TOTAL PROFIT: #{'%.8f' % profit_total}  (#{'%7s' % formatted_currency(profit_total * current_price)})" 
    results << "    GRAND TOTAL: #{'%.8f' % coin_total}  (#{'%7s' % formatted_currency(coin_total * current_price)})" 
    
    results.each { |r| puts r }
    puts "\n"
    

    
  end
  
  def formatted_currency( amount )
    amount = '%.2f' % amount
    '$' + amount
  end
  
  desc 'Print report by most active'
  task :activity => :environment do
  
    ## Usage:
    ## rake reports:activity COIN=ETH TOKEN=REQ
    
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
    results << "\nActivity Report For #{trading_pair.symbol}\n\n"
    results << "#{'%-3s' % 'ID'}  #{'%-8s' % 'STRATEGY'}  #{'%3s' % 'BUY%'}   #{'%3s' % 'SELL%'}  #{'%3s' % 'CLG%'}  #{'%5s' % 'SELLS'}  #{'%6s' % 'TOTAL ' + trading_pair.coin.symbol}  #{'%23s' % 'LAST ACTION'}  #{'%5s' % 'SIDE'} #{'%10s' % 'PRICE'}"
    results << "------------------------------------------------------------------------------------------------"
    
    bots = Trader.where( trading_pair: trading_pair, active: true ).to_a.sort_by( &:show_last_fulfilled_order_date ).reverse
    bots.each do |bot|
      
      last_action_date = bot.show_last_fulfilled_order_date
      if last_action_date
        last_action_words = "#{time_ago_in_words( last_action_date ) } ago"
      else
        last_action_words = ''
      end

      side = bot.current_order ? bot.current_order.side : '---'
      price = bot.current_order ? bot.current_order.price : 0
      results << "#{'%-3s' % bot.id.to_s}  #{'%-8s' % bot.strategy.name}  #{'%.3f' % bot.buy_pct}  #{'%.3f' % bot.sell_pct}  #{'%.3f' % bot.ceiling_pct}  #{'%4s' % bot.sell_count}  #{'%.8f' % bot.coin_amount}  #{'%22s' % last_action_words }  #{'%4s' % side}  #{'%.8f' % price}"
      
    end
    
    results.each { |r| puts r }
    puts "\n"
 
  end
  
end