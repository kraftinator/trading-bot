require './lib/strategies/trading_strategy_new.rb' 

class EpsilonStrategyNew < TradingStrategyNew
  
  def buy_order_limit_price
    if ( @tps.last_price > ( @tps.weighted_avg_price * 1.1 ) ) 
      limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
    else
      limit_price = @tps.last_price
    end
    ## Get target limit price based on percentage range.
    limit_price = limit_price * ( 1 - @trader.buy_pct )
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @trading_pair.price_precision )
    limit_price
  end
  
end