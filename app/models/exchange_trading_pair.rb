class ExchangeTradingPair < ApplicationRecord
  
   belongs_to :exchange
   belongs_to :coin1, :class_name => "ExchangeCoin"
   belongs_to :coin2, :class_name => "ExchangeCoin"
   
   has_many :campaigns
   has_many :trading_pair_stats
   has_many :index_fund_coins
   
   def stats
     return nil if trading_pair_stats.empty?
     trading_pair_stats.order( 'created_at desc' ).first
   end
   
   def cached_stats
     if trading_pair_stats.empty?
       load_stats
     end
     trading_pair_stats.order( 'created_at desc' ).first
   end
   
   
   def tps
     load_stats
     trading_pair_stats.order( 'created_at desc' ).first
   end
   
   def load_stats
     
     tps = stats
     #if tps.nil? or tps.updated_at < 1.minute.ago
     if tps.nil? or tps.updated_at < 30.seconds.ago
       
       case exchange.name
       when 'Binance'
         
         ## Get userless client
         client = exchange.userless_client
         ## Get 24 hour trading stats
         twenty_four_hour = client.twenty_four_hour( symbol: symbol )
         ## Get depth chart
         depth = client.depth( symbol: symbol )
         ## Calculate bid total
         bids = depth['bids']
         bid_total = 0
         bids.each { |b| bid_total += b[0].to_f * b[1].to_f }
         ## Calculate ask total
         asks = depth['asks']
         ask_total = 0
         asks.each { |a| ask_total += a[0].to_f * a[1].to_f }
         
         ## Create new Trading Pair Stat
         TradingPairStat.create(
             exchange_trading_pair: self,
             last_price: twenty_four_hour['lastPrice'],
             low_price: twenty_four_hour['lowPrice'],
             high_price: twenty_four_hour['highPrice'],
             weighted_avg_price: twenty_four_hour['weightedAvgPrice'],
             price_change_pct: twenty_four_hour['priceChangePercent'],
             volume: twenty_four_hour['volume'],
             bid_total: bid_total,
             ask_total: ask_total
             )
             
        when 'Coinbase'
          
          ## Get userless clients
          client = exchange.userless_client
          ## Get 24 hour trading stats
          daily_stats = nil
          #client.daily_stats( product_id: "#{coin1.symbol}-#{coin2.symbol}" ) do |resp|
          #  daily_stats = resp
          #end
          
          ## Get daily stats from Cryptocompare
          resp = HTTParty.get("https://min-api.cryptocompare.com/data/pricemultifull?fsyms=#{coin1.symbol}&tsyms=#{coin2.symbol}&e=#{exchange.name}")
          parsed_resp = resp.parsed_response
          if parsed_resp['Response'] == "Error"
            puts "ERROR: #{parsed_resp.message}"
          end
          ## Extract daily stats from response
          daily_stats = parsed_resp['RAW'][coin1.symbol][coin2.symbol]
          ## Set stats fields
          last_price = daily_stats['PRICE']
          low_price = daily_stats['LOW24HOUR']
          high_price = daily_stats['HIGH24HOUR']
          volume = daily_stats['VOLUME24HOUR']
          price_change_pct = daily_stats['CHANGEPCT24HOUR']
          
          ## Get depth chart
          depth = nil
          client.orderbook( level: 2, product_id: "#{coin1.symbol}-#{coin2.symbol}" ) do |resp|
            depth = resp
          end
          ## Calculate bid total
          bids = depth['bids']
          bid_total = 0
          bids.each { |b| bid_total += b[0].to_f * b[1].to_f }
          ## Calculate ask total
          asks = depth['asks']
          ask_total = 0
          asks.each { |a| ask_total += a[0].to_f * a[1].to_f }
          
          ## Get weighted avg price from Cryptocompare
          resp = HTTParty.get("https://min-api.cryptocompare.com/data/dayAvg?fsym=#{coin1.symbol}&tsym=#{coin2.symbol}&e=#{exchange.name}")
          results = resp.parsed_response
          if results['Response'] == "Error"
            puts "ERROR: #{results.message}"
          end  
          weighted_avg_price = results[coin2.symbol]
          
          ## Create new Trading Pair Stat
          TradingPairStat.create(
              exchange_trading_pair: self,
              last_price: last_price,
              low_price: low_price,
              high_price: high_price,
              weighted_avg_price: weighted_avg_price,
              price_change_pct: price_change_pct,
              volume: volume,
              bid_total: bid_total,
              ask_total: ask_total
              )

       end
     end
   end
   
  def sibling( exchange )
    c2 = coin2.coin
    ec2 = ExchangeCoin.where( exchange: exchange, coin: c2 ).first
    unless ec2
      case coin2.symbol
      when 'USD'
        c2 = Coin.where( symbol: 'USDT' ).first
        ec2 = ExchangeCoin.where( exchange: exchange, coin: c2 ).first
      end
    end
    return nil unless ec2
    ec2
  end
   
   def symbol
     "#{coin1.symbol}#{coin2.symbol}"
   end
  
   def display_name
     "#{coin1.symbol}/#{coin2.symbol}"
   end   
  
   def full_display_name
     "#{exchange.name} - #{display_name}"
   end
   
   def coin1_symbol
     coin1.symbol
   end
   
   def force_load_stats
     
       
       case exchange.name
       when 'Binance'
         
         ## Get userless client
         client = exchange.userless_client
         ## Get 24 hour trading stats
         twenty_four_hour = client.twenty_four_hour( symbol: symbol )
         ## Get depth chart
         depth = client.depth( symbol: symbol )
         ## Calculate bid total
         bids = depth['bids']
         bid_total = 0
         bids.each { |b| bid_total += b[0].to_f * b[1].to_f }
         ## Calculate ask total
         asks = depth['asks']
         ask_total = 0
         asks.each { |a| ask_total += a[0].to_f * a[1].to_f }
         
         ## Create new Trading Pair Stat
         TradingPairStat.create(
             exchange_trading_pair: self,
             last_price: twenty_four_hour['lastPrice'],
             low_price: twenty_four_hour['lowPrice'],
             high_price: twenty_four_hour['highPrice'],
             weighted_avg_price: twenty_four_hour['weightedAvgPrice'],
             price_change_pct: twenty_four_hour['priceChangePercent'],
             volume: twenty_four_hour['volume'],
             bid_total: bid_total,
             ask_total: ask_total
             )
             
        when 'Coinbase'
          
          ## Get userless clients
          client = exchange.userless_client
          ## Get 24 hour trading stats
          daily_stats = nil
          #client.daily_stats( product_id: "#{coin1.symbol}-#{coin2.symbol}" ) do |resp|
          #  daily_stats = resp
          #end
          
          ## Get daily stats from Cryptocompare
          resp = HTTParty.get("https://min-api.cryptocompare.com/data/pricemultifull?fsyms=#{coin1.symbol}&tsyms=#{coin2.symbol}&e=#{exchange.name}")
          parsed_resp = resp.parsed_response
          if parsed_resp['Response'] == "Error"
            puts "ERROR: #{parsed_resp.message}"
          end
          ## Extract daily stats from response
          daily_stats = parsed_resp['RAW'][coin1.symbol][coin2.symbol]
          ## Set stats fields
          last_price = daily_stats['PRICE']
          low_price = daily_stats['LOW24HOUR']
          high_price = daily_stats['HIGH24HOUR']
          volume = daily_stats['VOLUME24HOUR']
          
          ## Get depth chart
          depth = nil
          client.orderbook( level: 2, product_id: "#{coin1.symbol}-#{coin2.symbol}" ) do |resp|
            depth = resp
          end
          ## Calculate bid total
          bids = depth['bids']
          bid_total = 0
          bids.each { |b| bid_total += b[0].to_f * b[1].to_f }
          ## Calculate ask total
          asks = depth['asks']
          ask_total = 0
          asks.each { |a| ask_total += a[0].to_f * a[1].to_f }
          
          ## Get weighted avg price from Cryptocompare
          resp = HTTParty.get("https://min-api.cryptocompare.com/data/dayAvg?fsym=#{coin1.symbol}&tsym=#{coin2.symbol}&e=#{exchange.name}")
          results = resp.parsed_response
          if results['Response'] == "Error"
            puts "ERROR: #{results.message}"
          end  
          weighted_avg_price = results[coin2.symbol]
          
          ## Create new Trading Pair Stat
          TradingPairStat.create(
              exchange_trading_pair: self,
              last_price: last_price,
              low_price: low_price,
              high_price: high_price,
              weighted_avg_price: weighted_avg_price,
              volume: volume,
              bid_total: bid_total,
              ask_total: ask_total
              )

       end

   end
  
end
