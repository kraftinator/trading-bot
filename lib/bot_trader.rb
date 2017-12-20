module BotTrader

  module_function
  
  TradingPairStatus = Struct.new( :last_price, :weighted_avg_price, :high_price )
  
  def process( trading_pair )
    
    ## Get client
    api_key    = ENV['BINANCE_API_KEY']
    secret_key = ENV['BINANCE_SECRET_KEY']
    @client = Binance::Client::REST.new( api_key: api_key, secret_key: secret_key )
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    
    ## Run bots
    traders = Trader.where( trading_pair: trading_pair, active: true ).to_a
    
    ## Any active bots found?
    if traders.any?
      ## Yes. Load 24 hour trading pair stats.
      twenty_four_hour = @client.twenty_four_hour( symbol: trading_pair.symbol )
      @tps = TradingPairStatus.new( twenty_four_hour['lastPrice'].to_f , 
                                    twenty_four_hour['weightedAvgPrice'].to_f , 
                                    twenty_four_hour['highPrice'].to_f )
      
      #@tps = TradingPairStatus.new( BigDecimal.new( twenty_four_hour['lastPrice'] ), 
      #                              BigDecimal.new( twenty_four_hour['weightedAvgPrice'] ), 
      #                              BigDecimal.new( twenty_four_hour['highPrice'] ) )

      
    else
      puts "No active bots found."
      break
    end
    
    traders.each do |trader|
      
      if trader.limit_orders.any?
        #TODO
      else
        ## New bot! 
        initial_order( trader )
      end

    end
    
  end
  
=begin
Get 24 hour weighted average

If lastPrice < weightedAvgPrice
  limitPrice = lastPrice - percentage  ## percentage might need to be algorithmic
else
  limitPrice = weightedAvgPrice - percentage
end

Create limit buy order
  
#####
last_price*(1-0.05)
 => 0.00034789 
#####
=end  
  
  #client.create_order symbol: 'XRPETH', side: 'BUY', type: 'LIMIT', timeInForce: 'GTC', quantity: '100.00000000', price: '0.00055000'
  
  def initial_order( trader )
    limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
    limit_price = limit_price * ( 1 - trader.percentage_range.to_f )
    qty = trader.coin_qty.to_f / limit_price
    ## Create limit order
    @client.create_test_order( symbol: trader.trading_pair.symbol, side: 'BUY', type: 'LIMIT', timeInForce: 'GTC', quantity: qty, price: limit_price )
  end
  
end