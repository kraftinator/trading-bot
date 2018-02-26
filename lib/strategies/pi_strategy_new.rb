require './lib/strategies/trading_strategy_new.rb' 

class PiStrategyNew < TradingStrategyNew
  
  #def initialize( opts={} )
  #  super( opts )
  #  @eth_tps = opts[:eth_status]
  #end
  
  def buy_order_limit_price
    ## Choose last price or weighted avg price, whichever is less.
    limit_price = ( @tps.last_price < @tps.weighted_avg_price ) ? @tps.last_price : @tps.weighted_avg_price
    
=begin
    if eth_percent_diff > 0.1
      ## Token price should go down
      ## Place very low buy order
      buy limit price is normal * 3
    elsif eth_percent_diff < 0.1
      ## Token price should go up
      ## Place high buy order
      buy limit price is 0.0025
    elsif eth_prcent_diff > 0.05
      buy limit price is normal * 2
    elsif eth_percent_diff < 0.05
      buy limit price is 0.005
    elsif eth_bid_total > ets_bid_total
      buy limit price is 0.005
    else
      buy limit price is normal
    end
=end
       
    if @fiat_tps.price_change_pct > 10
      limit_price = limit_price * ( 1 - @trader.buy_pct - 0.1 )
    elsif @fiat_tps.price_change_pct > 5
      limit_price = limit_price * ( 1 - @trader.buy_pct - 0.05 )
    elsif @fiat_tps.price_change_pct < -10
      limit_price = limit_price * ( 1 - 0.005 )
    elsif @fiat_tps.price_change_pct < -5
      limit_price = limit_price * ( 1 - 0.005 )
    elsif @tps.price_change_pct > 10
      limit_price = limit_price * ( 1 - @trader.buy_pct - 0.1 )
    elsif @tps.price_change_pct > 5
      limit_price = limit_price * ( 1 - @trader.buy_pct - 0.05 )
    elsif @tps.price_change_pct < -10
      limit_price = limit_price * ( 1 - @trader.buy_pct - 0.1 )
    elsif @tps.price_change_pct < -5
      limit_price = limit_price * ( 1 - @trader.buy_pct - 0.05 )
    else
      limit_price = limit_price * ( 1 - @trader.buy_pct )
    end
        
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @trading_pair.price_precision )
    limit_price
  end
  
  def sell_order_limit_price
    ## Get token quantity
    qty = @trader.token_qty.truncate( @trading_pair.qty_precision )
    ## Calculate expected SELL coin total
    buy_coin_total = @api_order.executed_qty * @api_order.price

    if @fiat_tps.price_change_pct > 10
      ## Token price expected to decrease
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @fiat_tps.price_change_pct > 5
      ## Token price expected to decrease
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @fiat_tps.price_change_pct < -10
      ## Token price expected to increase
      sell_coin_total = buy_coin_total * ( 1 + @trader.sell_pct )
    elsif @fiat_tps.price_change_pct < -5
      ## Token price expected to increase
      sell_coin_total = buy_coin_total * ( 1 + @trader.sell_pct )
    elsif @tps.price_change_pct > 10
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @tps.price_change_pct > 5
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @tps.price_change_pct < -10
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @tps.price_change_pct < -5
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    else
      sell_coin_total = buy_coin_total * ( 1 + @trader.sell_pct )
    end
    
    ## Calculate limit price from SELL coin total
    limit_price = sell_coin_total / qty
    ## If last price > limit price, set limit price to last price
    limit_price = @tps.last_price if limit_price < @tps.last_price
    ## Add precision to limit price. API will reject if too long. 
    limit_price = limit_price.round( @trading_pair.price_precision )
    limit_price
  end

end