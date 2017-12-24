require './lib/trading_strategy.rb' 

class EpsilonStrategy < TradingStrategy
  
  def buy_order_limit_price
    ## Choose last price or weighted avg price, whichever is less.
    limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
    ## Get target limit price by randomizing number between 0.01 and 0.2
    limit_price = limit_price * ( 1 - ( 0.01 + rand(99)/10000.0 ) )
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
end
