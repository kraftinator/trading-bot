module CoinbaseFactory

  module_function
  
  def update_trading_pairs
    
    ## Get client
    exchange = Exchange.where( name: 'Coinbase' ).first
    client = exchange.userless_client
    
    ## Get trading pair data
    currencies = client.currencies
    products = client.products
    
    puts "Loading #{exchange.name} trading pairs..."
    
    products.each do |product|
      
      ## Get Coin 1 (base)
      exchange_coin1 = exchange.coins.where( symbol: product['base_currency'] ).first
      unless exchange_coin1
        coin = Coin.where( symbol: product['base_currency'] ).first
        unless coin
          coin = Coin.create( symbol: product['base_currency'] )
          puts "Created new coin: #{coin.symbol}"
        end
        exchange_coin1 = exchange.coins.create( coin: coin, symbol: coin.symbol )
      end
      
      ## Get Coin 2 (quote)
      exchange_coin2 = exchange.coins.where( symbol: product['quote_currency'] ).first
      unless exchange_coin2
        coin = Coin.where( symbol: product['quote_currency'] ).first
        unless coin
          coin = Coin.create( symbol: product['quote_currency'] )
          puts "Created new coin: #{coin.symbol}"
        end
        exchange_coin2 = exchange.coins.create( coin: coin, symbol: coin.symbol )
      end
      
      ##################################################
      ## Extract precisions
      ##################################################
      
      ## Price precision
      quote_increment = product['quote_increment']
      quote_increment = quote_increment.gsub('.','')
      price_precision = quote_increment.index('1')
      
      ## Quantity precision
      base_currency = currencies.select { |c| c['id'] == exchange_coin1.symbol }.first
      min_size = base_currency['min_size']
      min_size = min_size.gsub('.','')
      qty_precision = min_size.index('1')
      
      ##################################################
      ## Update exchange trading pair
      ##################################################
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

    end  ## products loop
    
  end  ## update_trading_pairs
  
end