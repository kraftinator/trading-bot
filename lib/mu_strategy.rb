require './lib/trading_strategy.rb' 

class MuStrategy < TradingStrategy
  
  ### Gamma-Iota Hybrid
  ### Currently using state to save different bot states
  ### 0 = gamma - default Gamma behavior
  ### 1 = kappa - normal Kappa buy pricing
  ### 2 = kappa_bear - bearish Kappa buy pricing cap
  ### 3 = iota - Iota behavior
  
  ### Sets buy price
  def buy_order_limit_price
    ### Gamma behavior
    if @trader.state == 'gamma'
      puts "Beginning gamma check"
      if ( @trader.ceiling_pct > 0 ) and ( @tps['last_price'] > ( @tps['weighted_avg_price'] * ( 1 + @trader.ceiling_pct.to_f ) ) )
        limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
      else
        limit_price = @tps['last_price']
      end
      if ((@tps['high_price'] * 0.9) <= limit_price) && (@tps['high_price'] > (@tps['low_price'] * 1.15))
        puts "Changing from gamma to kappa_bear"
        puts "High price is #{@tps['high_price']} and low price is #{@tps['low_price']}"
        @trader.update(state: 'kappa_bear')
      else
        ## Get target limit price based on buy pct.
        limit_price = limit_price * ( 1 - @trader.buy_pct.to_f )
      end
    end
    ### Normal Kappa behavior
    if @trader.state == 'kappa'
      ## Set limit price to low price
      puts "Setting kappa price"
      limit_price =  @tps['low_price']
    end
    ### Bearish Kappa behavior
    if @trader.state == 'kappa_bear'
      puts "Setting kappa_bear price"
      ## Set limit price to low price
      limit_price =  @tps['low_price']
      limit_price =  limit_price * ( 1 - @trader.buy_pct.to_f )
    end
    ### Iota behavior
    if @trader.state == 'iota'
      puts "Executing iota behavior"
      ## Choose last price or weighted avg price, whichever is less.
      limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
      if (@tps['low_price'] * 1.1) >= limit_price
        @trader.update(state: 'gamma')
      end
      if @trader.state == 'iota'
        ## Get target limit price based on percentage range and reduce by 5%. This bot is a conservative Alpha.
        limit_price = limit_price * ( 1 - @trader.sell_pct.to_f - 0.05 )
      elsif @trader.state == 'gamma'
        if ( @trader.ceiling_pct > 0 ) and ( @tps['last_price'] > ( @tps['weighted_avg_price'] * ( 1 + @trader.ceiling_pct.to_f ) ) )
          limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
        else
          limit_price = @tps['last_price']
        end
        ## Get target limit price based on buy pct.
        limit_price = limit_price * ( 1 - @trader.buy_pct.to_f )
      end
    end
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end

  
  ### Changes the buy order price
  def process_open_buy_order
    ## Determine if limit order needs to be replaced.
    limit_order = @trader.current_order
    ### Check if bot is a bearish Kappa and only change price every wait_period - usually 24 hours
    if @trader.state == 'kappa_bear'
      if @trader.wait_period.minutes.ago > limit_order.created_at
        ## Determine new limit price
        limit_price = buy_order_limit_price
        ## If new limit price > original limit price, replace original order
        if limit_price > limit_order.price
          ## Cancel current order
          result = @client.cancel_order( symbol: @trader.trading_pair.symbol, orderId: limit_order.order_guid )
          if result['code']
            puts "ERROR: #{result['code']} #{result['msg']}"
            return false
          end
          ## Cancel local limit order
          limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
          ## Create new limit order
          create_buy_order( limit_price )
        end
      end
    else
      ### If not bearish Kappa then act normal
      ## Determine new limit price
      limit_price = buy_order_limit_price
      ## If new limit price > original limit price, replace original order
      if limit_price > limit_order.price
        ## Cancel current order
        result = @client.cancel_order( symbol: @trader.trading_pair.symbol, orderId: limit_order.order_guid )
        if result['code']
          puts "ERROR: #{result['code']} #{result['msg']}"
          return false
        end
        puts "Order #{limit_order.order_guid} canceled."
        ## Cancel local limit order
        limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
        ## Create new limit order
        create_buy_order( limit_price )
      end
    end
  end
   
  
  def process_filled_sell_order
    ## Yay! The order was successfully filled!
    ## Close the limit order.
    @trader.current_order.update( open: false, state: LimitOrder::STATES[:filled], filled_at: Time.current, eth_price: @eth_status['last_price'] )
    ## Update trader's coin and token quantities
    coin_qty = ( @current_order['executedQty'].to_f * @current_order['price'].to_f ).round( @precision )
    token_qty = @current_order['executedQty'].to_f
    ## Update trader
    @trader.update( coin_qty: @trader.coin_qty + coin_qty, token_qty: @trader.token_qty - token_qty,  sell_count: @trader.sell_count + 1 )
    ## Checks if bot behavior needs to be changed
    puts "JMK beginning of if statement in process_filled_sell_order"
    puts "Bot id is #{@trader.id} and Bot state is #{@trader.state}"
    if rand(100) + 1 > 95 && @trader.state == 'gamma'
      @trader.update(state: 'kappa')
      puts "JMK state updated to kappa"
    elsif @trader.state == 'kappa' || @trader.state == 'kappa_bear'
      @trader.update(state: 'iota')
      puts "JMK state updated to iota"
    end
    if @trader.strategy_id == 15
      puts @trader.id
      puts @trader.state
    end
    puts "Bot id is #{@trader.id} and Bot state is #{@trader.state}"
    puts "JMK end of if statement in process_filled_sell_order"
    ## Create new buy order
    create_buy_order( buy_order_limit_price )
  end
  
end