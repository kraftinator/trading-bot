module BinanceFactory

  module_function
  
  def update_trading_pairs
    
    exchange = Exchange.where( name: 'Binance' ).first
    client = exchange.userless_client
    exchange_info = client.exchange_info
    trading_pairs = exchange_info['symbols']
    trading_pairs.each do |tp|
      
      ## Get Coin 1
      exchange_coin1 = exchange.coins.where( symbol: tp['baseAsset'] ).first
      unless exchange_coin1
        coin = Coin.where( symbol: tp['baseAsset'] ).first
        unless coin
          coin = Coin.create( symbol: tp['baseAsset'] )
          puts "Created new coin: #{coin.symbol}"
        end
        exchange_coin1 = exchange.coins.create( coin: coin, symbol: coin.symbol )
      end
      
      ## Get Coin 2
      exchange_coin2 = exchange.coins.where( symbol: tp['quoteAsset'] ).first
      unless exchange_coin2
        coin = Coin.where( symbol: tp['baseAsset'] ).first
        unless coin
          coin = Coin.create( symbol: tp['baseAsset'] )
          puts "Created new coin: #{coin.symbol}"
        end
        exchange_coin2 = exchange.coins.create( coin: coin, symbol: coin.symbol )
      end
      
      #########################
      ## Extract precisions
      #########################
      filters = tp['filters']
      
      ## Price precision
      price_filter = filters.select { |f| f['filterType'] == 'PRICE_FILTER' }.first
      tick_size = price_filter['tickSize']
      tick_size = tick_size.gsub('.','')
      price_precision = tick_size.index('1')

      ## Quantity precision
      lot_size = filters.select { |f| f['filterType'] == 'LOT_SIZE' }.first
      step_size = lot_size['stepSize']
      step_size = step_size.gsub('.','')
      qty_precision = step_size.index('1')

      ## Create Exchange Trading Pair
      etp = exchange.trading_pairs.where( coin1: exchange_coin1, coin2: exchange_coin2 ).first
      if etp
        ## Update trading pair with precisions
        etp.update( price_precision: price_precision, qty_precision: qty_precision )
        puts "Updated #{etp.symbol}"
      else
        ## Create new trading pair
        etp = exchange.trading_pairs.create( coin1: exchange_coin1, coin2: exchange_coin2, price_precision: price_precision, qty_precision: qty_precision )
        puts "Created #{etp.symbol}"
      end
      
    end
    
  end

end