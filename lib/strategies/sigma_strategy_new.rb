require './lib/strategies/trading_strategy_new.rb' 

class SigmaStrategyNew < TradingStrategyNew
  
  def buy_order_limit_price
    if @trader.sell_count_trigger > 0 && @trader.sell_count > 0 && @trader.sell_count % @trader.sell_count_trigger == 0
      limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
      limit_price = limit_price * ( 1 - @trader.buy_pct - 0.05 )
    else
      if ( @trader.ceiling_pct > 0 ) and ( @tps.last_price > ( @tps.weighted_avg_price * ( 1 + @trader.ceiling_pct ) ) )
        limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
      else
        limit_price = @tps.last_price
      end
      ## Get target limit price based on buy pct.
      limit_price = limit_price * ( 1 - @trader.buy_pct )
    end
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @trading_pair.price_precision )
    limit_price    
  end

end