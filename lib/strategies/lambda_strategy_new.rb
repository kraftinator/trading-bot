require './lib/strategies/trading_strategy_new.rb' 

class LambdaStrategyNew < TradingStrategyNew
  
  def process_open_sell_order
    ## Get current limit order
    limit_order = @trader.current_order
    ## Lower limit price if time thresholds are met
    if 8.hours.ago > limit_order.created_at
      ## Choose last price or weighted avg price, whichever is greater.
      limit_price = ( @tps.last_price > @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
      limit_price = limit_price * 1.01
      limit_price = limit_price.round( @trading_pair.price_precision )
      ## Calculate new coin qty
      new_coin_qty = limit_order.qty * limit_price
      ## Calculate percentage difference
      percentage_diff = ( 1 - limit_price / limit_order.price )
      ## If original coin qty < new coin qty and diff less than 20%, place loss SELL order      
      if new_coin_qty > @trader.original_coin_qty and percentage_diff < 0.2
        ## Cancel current order
        @trader.cancel_current_order
        ## Create new limit order
        create_sell_order( limit_price )
      end
      
    elsif 4.hours.ago > limit_order.created_at
      ## Get buy price
      buy_order = limit_order.buy_order
      if buy_order      
        ## Lower price to 1 percent above buy
        limit_price = buy_order.price * 1.005
        limit_price = @tps.last_price if limit_price < @tps.last_price
        ## Add precision to limit price. API will reject if too long.           
        limit_price = limit_price.round( @trading_pair.price_precision )
        if limit_price < limit_order.price
          ## Cancel current order
          @trader.cancel_current_order
          ## Create new limit order
          create_sell_order( limit_price )
        end
      end      
    end
    
  end
  
end