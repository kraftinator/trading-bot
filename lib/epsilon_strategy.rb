require './lib/trading_strategy.rb' 

class EpsilonStrategy < TradingStrategy
    
  def buy_order_limit_price
    ## Set limit price to last price if it's not 10% > weighted avg price and high price is not 10% > weighted avg price.
    ## This is a more conservative type of Gamma bot.
    if ( @tps['last_price'] > ( @tps['weighted_avg_price'] * 1.1 ) ) #or ( @tps['high_price'] > ( @tps['weighted_avg_price'] * 1.1 ) )
      #limit_price = @tps['weighted_avg_price']
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
  
  
=begin
  def buy_order_limit_price
    ## Choose last price or weighted avg price, whichever is less.
    limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
    ## Get target limit price by randomizing number between 0.01 and 0.2
    limit_price = limit_price * ( 1 - ( 0.01 + rand(99)/10000.0 ) )
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
=end
    
end
