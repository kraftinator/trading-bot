require './lib/trading_strategy.rb' 

class GammaStrategy < TradingStrategy
  
  #############################################
  #############################################
  ## BUY order limit price is set to Last Price.
  ## This makes the bot more aggressive when
  ## placing a limit BUY order.
  #############################################
  #############################################
  def buy_order_limit_price
    ## Choose last price.
    limit_price = @tps['last_price']
    ## Get target limit price based on percentage range.
    limit_price = limit_price * ( 1 - @trader.percentage_range.to_f )
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
end