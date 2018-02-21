require './lib/trading_strategy.rb'

=begin
This bot replaces both the ETA and the KAPPA
Buy_pct and sell_pct should be expressed as integers and correspond to days
For example, buy_pct 10 would buy at the 10 day low and sell_pct 5 would sell at the 5 day high
Setting state to 'floor' will make it behave like an ETA
Setting state to 'ceiling' will make it behave like a KAPPA
Percentage_range should be expressed as a percent like it normally would
If percentage_range:0.05 and state:'floor' then the bot will sell at 5 percent above the buy price
If percentage_range:0.05 and state:'ceiling' then the bot will sell at 5 percent below the high price
=end

class NuStrategy < TradingStrategy
  
  def buy_order_limit_price
    ## Set limit price to lowest price based on the number in buy_pct in days
    @klines = @client.klines(symbol:@trader.trading_pair.symbol, interval:'1d', limit: @trader.buy_pct)
    @klines = @klines.sort {|a,b| a[3] <=> b[3]}    #returns smallest low price
    limit_price = @klines[0][3]
    ## Add precision to limit price. API will reject if too long.
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
  def sell_order_limit_price
    ## Set limit price to highest price based on the number in sell_pct in days if state is ceiling
    if @trader.state == 'ceiling'
      @klines = @client.klines(symbol:@trader.trading_pair.symbol, interval:'1d', limit: @trader.sell_pct)
      @klines = @klines.sort {|a,b| b[2] <=> a[2]}    #returns highest high price
      if (@klines[0][2].to_f * (1 - @trader.percentage_range.to_f)) > @current_order['price'].to_f
        limit_price = @klines[0][2].to_f * (1 - @trader.percentage_range.to_f)
      elsif @klines[0][2].to_f > @current_order['price'].to_f
        limit_price = @klines[0][2].to_f
      else
        limit_price = @current_order['price'].to_f * 1.005
      end
    elsif @trader.state == 'floor'
      ## Get token quantity
      qty = ( @trader.token_qty.to_f ).floor
      ## Calculate expected SELL coin total
      buy_coin_total = @current_order['executedQty'].to_f * @current_order['price'].to_f
      sell_coin_total = buy_coin_total * ( 1 + @trader.percentage_range.to_f )
      #sell_coin_total = sell_coin_total.floor( @precision )
      ## Calculate limit price from SELL coin total
      limit_price = sell_coin_total / qty
    end 
    ## If last price > limit price, set limit price to last price
    limit_price = @tps['last_price'] if limit_price < @tps['last_price']
    ## Add precision to limit price. API will reject if too long.           
    limit_price = limit_price.round( @precision )
    limit_price
  end
  
  def process_open_sell_order
    @klines = @client.klines(symbol:@trader.trading_pair.symbol, interval:'1d', limit: @trader.sell_pct)
    @klines = @klines.sort {|a,b| b[2] <=> a[2]}    #returns highest high price
    ## Get current limit order
    limit_order = @trader.current_order
    ## If high price has moved lower, then lower limit price.
    if limit_order.price.to_f > (@klines[0][2].to_f * (1 - @trader.percentage_range.to_f))
      ## Get buy price
      buy_order = limit_order.buy_order
      if buy_order && @trader.state == 'ceiling'
        ## Lower price to current high price
        if (@klines[0][2].to_f * (1 - @trader.percentage_range.to_f)) > buy_order.price.to_f
          limit_price = @klines[0][2].to_f * (1 - @trader.percentage_range.to_f)
        elsif @klines[0][2].to_f > buy_order.price.to_f
          limit_price = @klines[0][2].to_f
        else
          limit_price = buy_order.price.to_f * 1.005
        end
        ## Add precision to limit price. API will reject if too long.           
        limit_price = limit_price.round( @precision )
        ## Proceed if new limit price is greater than buy price.
        if limit_price > buy_order.price.to_f
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