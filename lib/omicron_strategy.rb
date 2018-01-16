require './lib/trading_strategy.rb' 

class OmicronStrategy < TradingStrategy
  
  def buy_order_limit_price
    ## Choose last price or weighted avg price, whichever is less.
    limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
    
    ## Set target price based on depth chart
    # 
    #if bid_total > ask_total
    #  place low buy order
    #else
    #  place normal buy order 
    #end

    #if bid_total > ask_total
    #  place normal sell order
    #else
    #  place low buy order
    #end
    
    if @tps['bid_total'] > @tps['ask_total']
      limit_price = limit_price * ( 1 - 0.005 )
    else
      ## Calculate percentage difference
      percentage_diff = ( 1 - @tps['bid_total'] / @tps['ask_total'] )
      if percentage_diff < 0.2
        limit_price = limit_price * ( 1 - 0.005 )
      else
        limit_price = limit_price * ( 1 - @trader.buy_pct.to_f )
      end
    end
    
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
  def sell_order_limit_price
    ## Get token quantity
    qty = ( @trader.token_qty.to_f ).floor
    ## Calculate expected SELL coin total
    buy_coin_total = @current_order['executedQty'].to_f * @current_order['price'].to_f
    
    if @tps['bid_total'] > @tps['ask_total']
      ## Calculate percentage difference
      percentage_diff = ( 1 - @tps['ask_total'] / @tps['bid_total'] )
      if percentage_diff < 0.2
        sell_coin_total = buy_coin_total * ( 1 + 0.005 )
      else
        sell_coin_total = buy_coin_total * ( 1 + @trader.sell_pct.to_f )
      end
    else
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    end
    
    
    ## Calculate limit price from SELL coin total
    limit_price = sell_coin_total / qty
    ## If last price > limit price, set limit price to last price
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## Add precision to limit price. API will reject if too long. 
    limit_price = limit_price.round( @precision )
    limit_price
  end

  
end