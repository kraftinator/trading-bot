require './lib/trading_strategy.rb' 

class PiStrategy < TradingStrategy
  
  def initialize( opts={} )
    super( opts )
    @eth_status = opts[:eth_status]
  end
  
  
  def buy_order_limit_price
    ## Choose last price or weighted avg price, whichever is less.
    limit_price = ( @tps['last_price'] < @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
    
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
       
    if @eth_status['price_change_pct'] > 10
      limit_price = limit_price * ( 1 - @trader.percentage_range.to_f - 0.1 )
    elsif @eth_status['price_change_pct'] > 5
      limit_price = limit_price * ( 1 - @trader.percentage_range.to_f - 0.05 )
    elsif @eth_status['price_change_pct'] < -10
      limit_price = limit_price * ( 1 - 0.005 )
    elsif @eth_status['price_change_pct'] < -5
      limit_price = limit_price * ( 1 - 0.005 )
    elsif @tps['price_change_pct'] > 10
      limit_price = limit_price * ( 1 - @trader.percentage_range.to_f - 0.1 )
    elsif @tps['price_change_pct'] > 5
      limit_price = limit_price * ( 1 - @trader.percentage_range.to_f - 0.05 )
    elsif @tps['price_change_pct'] < -10
      limit_price = limit_price * ( 1 - @trader.percentage_range.to_f - 0.1 )
    elsif @tps['price_change_pct'] < -5
      limit_price = limit_price * ( 1 - @trader.percentage_range.to_f - 0.05 )
    else
      limit_price = limit_price * ( 1 - @trader.percentage_range.to_f )
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

    if @eth_status['price_change_pct'] > 10
      ## Token price expected to decrease
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @eth_status['price_change_pct'] > 5
      ## Token price expected to decrease
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @eth_status['price_change_pct'] < -10
      ## Token price expected to increase
      sell_coin_total = buy_coin_total * ( 1 + @trader.percentage_range.to_f )
    elsif @eth_status['price_change_pct'] < -5
      ## Token price expected to increase
      sell_coin_total = buy_coin_total * ( 1 + @trader.percentage_range.to_f )
    elsif @tps['price_change_pct'] > 10
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @tps['price_change_pct'] > 5
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @tps['price_change_pct'] < -10
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    elsif @tps['price_change_pct'] < -5
      sell_coin_total = buy_coin_total * ( 1 + 0.005 )
    else
      sell_coin_total = buy_coin_total * ( 1 + @trader.percentage_range.to_f )
    end
    
    ## Calculate limit price from SELL coin total
    limit_price = sell_coin_total / qty
    ## If last price > limit price, set limit price to last price
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## Add precision to limit price. API will reject if too long. 
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
  def process_open_sell_order
    ## Get current limit order
    limit_order = @trader.current_order
    ## Lower limit price if time thresholds are met
    if 8.hours.ago > limit_order.created_at
      ## Choose last price or weighted avg price, whichever is greater.
      limit_price = ( @tps['last_price'] > @tps['weighted_avg_price'] ) ? @tps['last_price'] : @tps['weighted_avg_price']
      limit_price = limit_price * 1.01
      limit_price = limit_price.round( @precision )
      ## Calculate new coin qty
      new_coin_qty = limit_order.qty * limit_price
      ## Calculate percentage difference
      percentage_diff = ( 1 - limit_price / limit_order.price )
      ## If original coin qty < new coin qty and diff less than 20%, place loss SELL order      
      if new_coin_qty > @trader.original_coin_qty and percentage_diff < 0.2
        ## Cancel current order
        result = @client.cancel_order( symbol: @trader.trading_pair.symbol, orderId: limit_order.order_guid )
        if result['code']
          puts "ERROR: #{result['code']} #{result['msg']}"
          return false
        end
        puts "Order #{limit_order.order_guid} canceled."
        ## Cancel local limit order
        limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )        
        ## Create new limit order
        create_sell_order( limit_price )
      end
      
    elsif 4.hours.ago > limit_order.created_at
      ## Get buy price
      buy_order = limit_order.buy_order
      if buy_order      
        ## Lower price to 1 percent above buy
        limit_price = buy_order.price.to_f * 1.005
        limit_price = @tps['last_price'] if limit_price < @tps['last_price']
        ## Add precision to limit price. API will reject if too long.           
        limit_price = limit_price.round( @precision )
        if limit_price < limit_order.price.to_f
          ## Cancel current order
          result = @client.cancel_order( symbol: @trader.trading_pair.symbol, orderId: limit_order.order_guid )
          if result['code']
            puts "ERROR: #{result['code']} #{result['msg']}"
            return false
          end
          puts "Order #{limit_order.order_guid} canceled."
          ## Cancel local limit order
          limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )        
          ## Create new limit order
          create_sell_order( limit_price )
        end
      end      
    end
    
  end
  
end