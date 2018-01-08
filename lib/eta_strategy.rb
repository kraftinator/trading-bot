require './lib/trading_strategy.rb' 

class EtaStrategy < TradingStrategy
  
  def buy_order_limit_price
    ## Choose last price or weighted avg price, whichever is less.
    limit_price =  @tps['low_price']
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
end