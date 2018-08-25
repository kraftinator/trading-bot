require './lib/strategies/trading_strategy_new.rb' 

class MuStrategyNew < TradingStrategyNew
  
  ### Gamma-Iota Hybrid
  ### Currently using state to save different bot states
  ### 0 = gamma - default Gamma behavior
  ### 1 = kappa - normal Kappa buy pricing
  ### 2 = kappa_bear - bearish Kappa buy pricing cap
  ### 3 = iota - Iota behavior
  
  ### Sets buy price
  def buy_order_limit_price
    
    ## Default state to gamma
    if @trader.state.nil?
      @trader.update( state: 'gamma' )
    end
    
    ### Gamma behavior
    if @trader.state == 'gamma' or @trader.state.nil?
      puts "Running gamma behavior"
      if ( @trader.ceiling_pct > 0 ) and ( @tps.last_price > ( @tps.weighted_avg_price * ( 1 + @trader.ceiling_pct ) ) )
        limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
      else
        limit_price = @tps.last_price
      end
      if ((@tps.high_price * 0.95) <= limit_price) && (@tps.high_price > (@tps.low_price * 1.15))
        puts "High price is #{@tps.high_price} and low price is #{@tps.low_price} and limit price is #{limit_price}"
        @trader.update(state: 'kappa_bear')
        ## Set limit price to low price
        limit_price = @tps.low_price
        limit_price = limit_price * ( 1 - @trader.buy_pct )
        limit_price = limit_price.round( @trading_pair.price_precision )
        limit_order = @trader.current_order
        if limit_order
          if limit_order.side == 'BUY' && limit_order.open == true
            
            ## Cancel current order
            if @trader.cancel_current_order
              create_buy_order( limit_price )
            else
              return false
            end
            
            #result = @client.cancel_order( symbol: @trader.trading_pair.symbol, orderId: limit_order.order_guid )
            #if result['code']
            #  puts "ERROR: #{result['code']} #{result['msg']}"
            #  return false
            #end
            ## Cancel local limit order
            #limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
            ## Create new limit order
            #create_buy_order( limit_price )
            
          end
        end
      else
        ## Get target limit price based on buy pct.
        limit_price = limit_price * ( 1 - @trader.buy_pct )
      end
    end
    ### Normal Kappa behavior
    if @trader.state == 'kappa'
      ## Set limit price to low price
      puts "Setting kappa price"
      limit_price =  @tps.low_price
    end
    ### Bearish Kappa behavior
    if @trader.state == 'kappa_bear'
      puts "Setting kappa_bear price"
      ## Set limit price to low price
      limit_price =  @tps.low_price
      limit_price =  limit_price * ( 1 - @trader.buy_pct )
    end
    ### Iota behavior
    if @trader.state == 'iota'
      puts "Executing iota behavior"
      ## Choose last price or weighted avg price, whichever is less.
      limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
      if @tps.last_price >= (@tps.low_price * 1.07)
        puts "Changing state to gamma and running gamma behavior"
        @trader.update(state: 'gamma')
      end
      if @trader.state == 'iota'
        ## Get target limit price based on percentage range and reduce by 5%. This bot is a conservative Alpha.
        limit_price = limit_price * ( 1 - @trader.sell_pct - 0.05 )
        puts "Setting iota pricing"
      elsif @trader.state == 'gamma'
        if ( @trader.ceiling_pct > 0 ) and ( @tps.last_price > ( @tps.weighted_avg_price * ( 1 + @trader.ceiling_pct ) ) )
          limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
        else
          limit_price = @tps.last_price
        end
        ## Get target limit price based on buy pct.
        limit_price = limit_price * ( 1 - @trader.buy_pct )
      end
    end
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @trading_pair.price_precision )
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
        
        ## Cancel current order
        if @trader.cancel_current_order
          create_buy_order( limit_price )
        else
          return false
        end
         
        ## Cancel current order
        #result = @client.cancel_order( symbol: @trader.trading_pair.symbol, orderId: limit_order.order_guid )
        #if result['code']
        #  puts "ERROR: #{result['code']} #{result['msg']}"
        #  return false
        #end
        ## Cancel local limit order
        #limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
        ## Create new limit order
        #create_buy_order( limit_price )
        
      end
    else
      ### If not bearish Kappa then act normal
      ## Determine new limit price
      limit_price = buy_order_limit_price
      ## If new limit price > original limit price, replace original order
      if limit_price > limit_order.price
        
        ## Cancel current order
        if @trader.cancel_current_order
          create_buy_order( limit_price )
        else
          return false
        end
        
        ## Cancel current order
        #result = @client.cancel_order( symbol: @trader.trading_pair.symbol, orderId: limit_order.order_guid )
        #if result['code']
        #  puts "ERROR: #{result['code']} #{result['msg']}"
        #  return false
        #end
        #puts "Order #{limit_order.order_guid} canceled."
        ## Cancel local limit order
        #limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
        ## Create new limit order
        #create_buy_order( limit_price )
        
      end
    end
  end
  
  def process_filled_sell_order
    
    ## Yay! The order was successfully filled!
    ## Close the limit order.
    @trader.current_order.update( open: false, state: LimitOrder::STATES[:filled], filled_at: Time.current, fiat_price: @fiat_tps.last_price )
    ## Update trader's coin and token quantities
    coin_qty = ( @api_order.executed_qty * @api_order.price ).round( @trading_pair.price_precision )
    token_qty = @api_order.executed_qty

    ## Update trader
    ## Checks if bot behavior needs to be changed
    if @trader.state == 'kappa' || @trader.state == 'kappa_bear'
      @trader.update( coin_qty: @trader.coin_qty + coin_qty, token_qty: @trader.token_qty - token_qty,  sell_count: @trader.sell_count + 1, state: 'iota' )
      puts "Bot #{@trader.id} state updated to iota"
    elsif rand(100) + 1 > 95 && @trader.state == 'gamma'
      @trader.update( coin_qty: @trader.coin_qty + coin_qty, token_qty: @trader.token_qty - token_qty,  sell_count: @trader.sell_count + 1, state: 'kappa' )
      puts "Bot #{@trader.id} state updated to kappa"
    else
      @trader.update( coin_qty: @trader.coin_qty + coin_qty, token_qty: @trader.token_qty - token_qty,  sell_count: @trader.sell_count + 1 )
    end
    puts "Bot id is #{@trader.id} and Bot state is #{@trader.state}"
    ## Create new buy order
    create_buy_order( buy_order_limit_price )
  end

  def process_open_sell_order
    ## Get current limit order
    limit_order = @trader.current_order
    if 8.hours.ago > limit_order.created_at && @trader.state == 'gamma'
      @trader.update(state:'iota')
    end
    
    if 24.hours.ago > limit_order.created_at
      
      if @trader.takes_loss?
        
        limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
        limit_price = limit_price * 1.005
        ## Add precision to limit price. API will reject if too long.           
        limit_price = limit_price.round( @trading_pair.price_precision )
        
        ## Calculate new coin qty
        new_coin_qty = limit_order.qty * limit_price
        
        ## Calculate percentage difference
        percentage_diff = ( 1 - limit_price / limit_order.price )
        
        ## If original coin qty < new coin qty and diff less than loss_pct, place loss SELL order      
        if new_coin_qty > @trader.original_coin_qty && percentage_diff < @trader.loss_pct && limit_price < limit_order.price
          if @trader.cancel_current_order
            create_sell_order( limit_price )
          else
            return false
          end
        end
        
      end

    elsif 12.hours.ago > limit_order.created_at
      
      ## Get buy price
      buy_order = limit_order.buy_order
      if buy_order 
             
        ## Try to sell for any profit
        limit_price = @tps.last_price
        ## Add precision to limit price. API will reject if too long.           
        limit_price = limit_price.round( @trading_pair.price_precision )
        
        if limit_price < limit_order.price && limit_price > buy_order.price
          if @trader.cancel_current_order
            create_sell_order( limit_price )
          else
            return false
          end
        end
             
             
        ## Lower price to 1 percent above buy
        #limit_price = buy_order.price * 1.01
        #limit_price = @tps.last_price if limit_price < @tps.last_price
        ## Add precision to limit price. API will reject if too long.           
        #limit_price = limit_price.round( @trading_pair.price_precision )
        #if limit_price < limit_order.price
        #  if @trader.cancel_current_order
        #    create_sell_order( limit_price )
        #  else
        #    return false
        #  end
        #end
        
        
      end # if buy_order
           
    end # if 24.hours.ago > limit_order.created_at
    
  end # def process_open_sell_order
  
end