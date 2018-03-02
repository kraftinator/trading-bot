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
    ### Gamma behavior
    if @trader.state == 'gamma'
      puts "Running gamma behavior"
      if ( @trader.ceiling_pct > 0 ) and ( @tps.last_price > ( @tps.weighted_avg_price * ( 1 + @trader.ceiling_pct ) ) )
        limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
      else
        limit_price = @tps.last_price
      end
      if ((@tps.high_price * 0.95) <= limit_price) && (@tps.high_price > (@tps.low_price * 1.2))
        puts "High price is #{@tps.high_price} and low price is #{@tps.low_price} and limit price is #{limit_price}"
        @trader.update(state: 'kappa_bear')
        ## Set limit price to low price
        limit_price =  @tps.low_price
        limit_price =  limit_price * ( 1 - @trader.buy_pct )
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
        limit_price = limit_price * ( 1 - @trader.buy_pct.to )
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
      if @tps['last_price'] >= (@tps['low_price'] * 1.07)
        puts "Changing state to gamma and running gamma behavior"
        @trader.update(state: 'gamma')
      end
      if @trader.state == 'iota'
        ## Get target limit price based on percentage range and reduce by 5%. This bot is a conservative Alpha.
        limit_price = limit_price * ( 1 - @trader.sell_pct.to_f - 0.05 )
        puts "Setting iota pricing"
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
  
end