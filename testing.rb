api_key    = ENV['BINANCE_API_KEY']
secret_key = ENV['BINANCE_SECRET_KEY']
@client = Binance::Client::REST.new( api_key: api_key, secret_key: secret_key )
OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)

def three_day_low
  @klines = @client.klines(symbol:'REQETH', interval:'1d', limit: 5)
  @klines = @klines.sort {|a,b| a[3] <=> b[3]}
  @low_price = @klines[0][3]
  @low_price
end

#Returns value between 0 and 100, higher number is more bullish
def aroon_up(pair_symbol, interval_time)
  @klines = @client.klines(symbol:pair_symbol, interval:interval_time, limit: 25)
  high_price = 0
  periods_ago_high = 0
  @klines.each_with_index{ |high, index|
    if high[2].to_f >= high_price.to_f
      high_price = high[2]
      periods_ago_high = 25 - index
    end
  }
  @aroon_up =((25 - periods_ago_high.to_f)/25)*100
  @aroon_up
end

#Returns value between 0 and 100, higher number is more bearish
def aroon_down(pair_symbol, interval_time)
  @klines = @client.klines(symbol:pair_symbol, interval:interval_time, limit: 25)
  low_price = @klines[0][3]
  periods_ago_low = 0
  @klines.each_with_index{ |low, index|
    if low[3].to_f <= low_price.to_f
      low_price = low[3]
      periods_ago_low = 25 - index
    end
  }
  @aroon_down = ((25 - periods_ago_low.to_f)/25)*100
  @aroon_down
end

#Tracks fast and slow period
#Positive number if fast period is rising faster than slow period
#Negative number if fast period is rising slower than slow period
#Pretty good but also can lag producing bad trade signals
def awesome_oscillator(pair_symbol, interval_time, limit_size)
  @klines = @client.klines(symbol:pair_symbol, interval:interval_time, limit:limit_size)
  #@klines = @klines.reverse
  slow_period = []
  fast_period = []
  slow_sma = []
  fast_sma = []
  awesome_oscillator = []
  count = 0
  #The following variables are temporary and just for calculating potential profits
  price_holder = []
  time_holder = []
  buy_count = 0
  sell_count = 0
  eth_total = 0.02
  token_total = 0.0
  buy_price = 0.0
  sell_price = 0.0
  profit_total = 0.02
  @klines.each_with_index{ |val, index|
    slow_sma[index-count] = (val[2].to_f + val[3].to_f)/2
    if index >= 29
      fast_sma[index-29-count] = (val[2].to_f + val[3].to_f)/2
    end
    if slow_sma.length == 34
      slow_sma_total = 0
      slow_sma.each do |sma_slow|
        slow_sma_total = slow_sma_total + sma_slow
      end
      slow_period[count] = (slow_sma_total/34)
      if fast_sma.length == 5
        fast_sma_total = 0
        fast_sma.each do |sma_fast|
          fast_sma_total = fast_sma_total + sma_fast
        end
        fast_period[count] = (fast_sma_total/5)
      end
      awesome_oscillator[count] = fast_period[count].to_f - slow_period[count].to_f
      price_holder[count] = ((val[2].to_f + val[3].to_f + val[4].to_f)/3).round(8)
      time_holder[count] = val[6]
      count += 1
      slow_sma = slow_sma.drop(1)
      fast_sma = fast_sma.drop(1)  
    end
  }
  hold = false
  awesome_oscillator.each_with_index{ |val, index|
    if awesome_oscillator[index-1]
      x = val * 1000
      if awesome_oscillator[index-1] < 0 && val > 0 && hold == false  #BUY
        hold = true
        token_total = eth_total / price_holder[index]
        buy_price = price_holder[index]
        if price_holder[index-1] > price_holder[index]
          puts "#{x.round(8)}    #{price_holder[index]}    ---    #{DateTime.strptime(time_holder[index].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    BUY"
        else
          puts "#{x.round(8)}    #{price_holder[index]}    +++    #{DateTime.strptime(time_holder[index].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    BUY"
        end
      elsif awesome_oscillator[index-1] > 0 && val < 0 && hold == true  #SELL
        hold = false
        profit_total += (token_total * price_holder[index]) - eth_total
        eth_total = token_total * price_holder[index]
        if price_holder[index-1] > price_holder[index]
          puts "#{x.round(8)}    #{price_holder[index]}    ---    #{DateTime.strptime(time_holder[index].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    SELL    #{profit_total.round(8)}"
        else
          puts "#{x.round(8)}    #{price_holder[index]}    +++    #{DateTime.strptime(time_holder[index].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    SELL    #{profit_total.round(8)}"
        end
      elsif hold == true
        if price_holder[index-1] > price_holder[index]
          puts "#{x.round(8)}    #{price_holder[index]}    ---    #{DateTime.strptime(time_holder[index].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    HOLD"
        else
          puts "#{x.round(8)}    #{price_holder[index]}    +++    #{DateTime.strptime(time_holder[index].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    HOLD"
        end
      else
        if price_holder[index-1] > price_holder[index]
          puts "#{x.round(8)}    #{price_holder[index]}    ---    #{DateTime.strptime(time_holder[index].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}"
        else
          puts "#{x.round(8)}    #{price_holder[index]}    +++    #{DateTime.strptime(time_holder[index].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}"
        end
      end
    end
  }
  puts "#{awesome_oscillator.length}"
  #awesome_oscillator = (fast_sma/5) - (slow_sma/34)
end

#Tracks price and volume and returns a number between 0 and 100
#80 or higher is considered overbought and is a good time to sell
#20 or lower is considered oversold and is a good time to buy
def money_flow_index(pair_symbol, interval_time, limit_size)
  @klines = @client.klines(symbol:pair_symbol, interval:interval_time, limit:limit_size)
  typical_price = []
  raw_money_flow = []
  positive_mf = []
  negative_mf = []
  money_flow_ratio = []
  money_flow_index = [] 
  hold = false
  mfi_high = false
  mfi_low = false
  @klines.each_with_index{ |val, index|
    typical_price[index] = (val[2].to_f + val[3].to_f + val[4].to_f) / 3
    if index > 0
      raw_money_flow[index] = typical_price[index] * val[7].to_f
      if typical_price[index] > typical_price[index-1]
        positive_mf[index] = raw_money_flow[index]
      else
        negative_mf[index] = raw_money_flow[index]
      end
      if typical_price.length > 14
        positive_money_flow = positive_mf.last(14)
        negative_money_flow = negative_mf.last(14)
        positive_mf_total = 0
        negative_mf_total = 0
        positive_money_flow.each { |positive|
          positive_mf_total += positive if positive
        }
        negative_money_flow.each { |negative|
          negative_mf_total += negative if negative
        }
        money_flow_ratio[index] = positive_mf_total / negative_mf_total
        money_flow_index[index] = 100 - 100 / (1 + money_flow_ratio[index])
      end
    end
    if money_flow_index[index]
      if money_flow_index[index-1]
        if money_flow_index[index-1] < 20 || mfi_low == true
          mfi_low = true if hold == false
          if money_flow_index[index] > 20 && hold != true
             hold = true
             mfi_low = false
            puts "#{money_flow_index[index].round(2)}   #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)} BUY"
          end
        elsif money_flow_index[index-1] > 80 || mfi_high == true
          mfi_high = true if hold == true
          if money_flow_index[index] < 70 && hold == true
            hold = false
            mfi_high = false
            puts "#{money_flow_index[index].round(2)}   #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)} SELL"      
          end
        elsif hold == true
          #puts "#{money_flow_index[index].round(2)}   #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)} HOLD" 
        else
          #puts "#{money_flow_index[index].round(2)}   #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}" 
        end  
      end
    end
  }
  @klines.length
end

#This one seems pretty inaccurate
def commodity_channel_index(pair_symbol, interval_time, limit_size)
  @klines = @client.klines(symbol:pair_symbol, interval:interval_time, limit:limit_size)
  typical_price = []
  twenty_period_sma = []
  last_twenty = []
  mean_deviation = []
  absolute_values = 0
  cci = []
  constant = 0.015
  hold = false
  cci_high = false
  cci_low = false
  @klines.each_with_index{ |val, index|
    typical_price[index] = (val[2].to_f + val[3].to_f + val[4].to_f) / 3
    if typical_price.length >= 20
      twenty_period_sma[index] = (typical_price.last(20).sum) / 20
      last_twenty = typical_price.last(20)
      last_twenty.each do |tp|
        absolute_values += (tp - twenty_period_sma[index]).abs
      end
      mean_deviation[index] = absolute_values / 20
      absolute_values = 0
      cci[index] = (typical_price[index] - twenty_period_sma[index]) / (constant * mean_deviation[index])
      if cci[index-1]
        if cci[index-1] < -100 || cci_low == true
          cci_low = true if hold == false
          if cci[index] > -100 && hold != true
            hold = true
            cci_low = false
            puts "#{cci[index].round(2)}    #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    BUY"
          elsif hold == true
             #puts "#{cci[index].round(2)}    #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    HOLD"
          else
            #puts "#{cci[index].round(2)}    #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}"
          end
        elsif cci[index-1] > 100 || cci_high == true
          cci_high = true if hold == true
          if cci[index] < 100 && hold == true
            hold = false
            cci_high = false
            puts "#{cci[index].round(2)}    #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    SELL"
          elsif hold == true
            #puts "#{cci[index].round(2)}    #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    HOLD"
          else
            #puts "#{cci[index].round(2)}    #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}"
          end
        elsif hold == true
          #puts "#{cci[index].round(2)}    #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    HOLD"
        else
          #puts "#{cci[index].round(2)}    #{typical_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}"
        end
      end
    end
  }
  nil
end

def exponential_moving_average(pair_symbol, interval_time, limit_size)
  @klines = @client.klines(symbol:pair_symbol, interval:interval_time, limit:limit_size)
  closing_price = []
  ten_period_sma = []
  variable_period_sma = []
  variable = 40 #for sma
  ema = []
  time_periods = 20 #for ema
  multiplier = (2.0 / (time_periods + 1.0))
  #Following variables are temporary and for calculating potential profits
  hold = false
  ema_high = false
  ema_low = false
  @klines.each_with_index{ |val, index|
    closing_price[index] = val[4].to_f
    if closing_price.length >= time_periods
      ten_period_sma[index] = (closing_price.last(time_periods.to_f).sum) / time_periods
      if !ema[index-1]
        ema[index-1] = 0.0
      end
      ema[index] = ((closing_price[index] - ema[index-1]) * multiplier) + ema[index-1]
    end
    if closing_price.length >= variable
      variable_period_sma[index] = (closing_price.last(variable).sum) / variable
    end
    if ema[index-1] && variable_period_sma[index-1]
      if ema[index-1] < variable_period_sma[index-1] || ema_low == true
        ema_low = true if hold == false
        if ema[index] > variable_period_sma[index] && hold != true
          hold = true
          ema_low = false
          puts "#{closing_price[index].round(8)}   #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    BUY"
        end
      elsif ema[index-1] > variable_period_sma[index] || ema_high == true
        ema_high = true if hold == true
        if ema[index] < variable_period_sma[index] && hold == true
          hold = false
          ema_high = false  
          puts "#{closing_price[index].round(8)}    #{DateTime.strptime(val[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)}    SELL"
          puts ""
        end
      end
      if ema[index] > variable_period_sma[index] 
        #puts "+++EMA #{ema[index].round(8)}    #{variable} Period SMA #{variable_period_sma[index].round(8)} Closing #{closing_price[index]}"
      elsif ema[index] < variable_period_sma[index]
        #puts "---EMA #{ema[index].round(8)}    #{variable} Period SMA #{variable_period_sma[index].round(8)} Closing #{closing_price[index]}"
      end
    end
  }
  multiplier
end

def kline_parser
  @klines.each do |x|
    open_time = DateTime.strptime(x[0].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)
    close_time = DateTime.strptime(x[6].to_s, '%Q').in_time_zone('Pacific Time (US & Canada)').to_s(:long)
    puts "OPEN TIME #{x[0]} or #{open_time}"
    puts "OPEN #{x[1]}"
    puts "HIGH #{x[2]}"
    puts "LOW #{x[3]}"
    puts "CLOSE #{x[4]}"
    puts "VOLUME #{x[5]}"
    puts "CLOSE TIME #{x[6]} or #{close_time}"
    puts "QUOTE ASSET VOLUME #{x[7]}"
    puts "NUMBER OF TRADES #{x[8]}"
    puts "TAKER BUY BASE ASSET VOLUME #{x[9]}"
    puts "TAKER BUY QUOTE ASSET VOLUME #{x[10]}"
    puts "IGNORE #{x[11]}"
    puts ""
  end
  nil
end




