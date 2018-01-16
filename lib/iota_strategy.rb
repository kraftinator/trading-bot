require './lib/trading_strategy.rb' 

class IotaStrategy < TradingStrategy
  
  def buy_order_limit_price
    ## Choose last price or weighted avg price, whichever is less.
    limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
    ## Get target limit price based on percentage range and reduce by 5%. This bot is a conservative Alpha.
    limit_price = limit_price * ( 1 - @trader.buy_pct.to_f - 0.05 )
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
end