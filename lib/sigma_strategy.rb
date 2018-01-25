require './lib/trading_strategy.rb' 

class SigmaStrategy < TradingStrategy
  
  def buy_order_limit_price
    if @trader.sell_count_trigger > 0 && @trader.sell_count % @trader.sell_count_trigger == 0
      limit_price =  @tps['low_price']
    else
      if ( @trader.ceiling_pct > 0 ) and ( @tps['last_price'] > ( @tps['weighted_avg_price'] * ( 1 + @trader.ceiling_pct.to_f ) ) )
        limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
      else
        limit_price = @tps['last_price']
      end
      ## Get target limit price based on buy pct.
      limit_price = limit_price * ( 1 - @trader.buy_pct.to_f )
    end
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price    
  end

end