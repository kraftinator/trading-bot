require './lib/trading_strategy.rb' 

class ZetaStrategy < TradingStrategy
    
  def buy_order_limit_price
    ## Set limit price to last price if high price is not 10% higher than weighted avg price.
    ## This is a more conservative type of Gamma and Epsilon bots.
    if @tps['high_price'] > ( @tps['weighted_avg_price'] * 1.1 )
      limit_price = @tps['weighted_avg_price']
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
