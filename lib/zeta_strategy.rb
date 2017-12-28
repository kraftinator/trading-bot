require './lib/trading_strategy.rb' 

class ZetaStrategy < TradingStrategy
    
  def buy_order_limit_price
    ## Set limit price to last price if it's not 5% > weighted avg price and high price is not 10% > weighted avg price.
    if ( @tps['last_price'] > ( @tps['weighted_avg_price'] * 1.05 ) ) or ( @tps['high_price'] > ( @tps['weighted_avg_price'] * 1.1 ) )
      limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
    else
      limit_price = @tps['last_price']
    end
    ## Get target limit price based on percentage range.
    limit_price = limit_price * ( 1 - @trader.percentage_range.to_f )
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
    
end
