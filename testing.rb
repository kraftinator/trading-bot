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
def aroon_up(pair_symbol)
  @klines = @client.klines(symbol:pair_symbol, interval:'1d', limit: 25)
  @high_price = 0
  @days_ago_high = 0
  @klines.each_with_index{ |high, index|
    if high[2].to_f >= @high_price.to_f
      @high_price = high[2]
      @days_ago_high = 25 - index
    end
  }
  @aroon_up =((25 - @days_ago_high.to_f)/25)*100
  @aroon_up
end

#Returns value between 0 and 100, higher number is more bearish
def aroon_down(pair_symbol)
  @klines = @client.klines(symbol:pair_symbol, interval:'1d', limit: 25)
  @low_price = @klines[0][3]
  @days_ago_low = 0
  @klines.each_with_index{ |low, index|
    if low[3].to_f <= @low_price.to_f
      @low_price = low[3]
      @days_ago_low = 25 - index
    end
  }
  @aroon_down = ((25 - @days_ago_low.to_f)/25)*100
  @aroon_down
end

def awesome_oscillator(pair_symbol, interval_time, limit_size)
  @klines = @client.klines(symbol:pair_symbol, interval:interval_time, limit:limit_size)
  #@klines = @klines.reverse
  slow_period = []
  fast_period = []
  slow_sma = []
  fast_sma = []
  count = 0
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
      count += 1
      slow_sma = slow_sma.drop(1)
      fast_sma = fast_sma.drop(1)  
    end
  }
  x = 0
  fast_period.each do |i|
    puts "#{(i - slow_period[x]).to_f} with Fast #{i} and Slow #{slow_period[x]}"
    x += 1
  end
  puts "#{fast_period.length} and #{slow_period.length}"
  #awesome_oscillator = (fast_sma/5) - (slow_sma/34)
end




