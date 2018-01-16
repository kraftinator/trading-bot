require './lib/bot_trader.rb' 

namespace :bots do
  
  desc 'Create bot'
  task :create => :environment do
    
    ## Usage:
    ## rake bots:create COIN=ETH TOKEN=REQ COIN_QTY=0.05 BUY_PCT=0.05 SELL_PCT=0.05 CEILING_PCT=0.05 WAIT_PERIOD=1440 STRATEGY=ALPHA
    
    puts "Creating bot..."
    
    ## Get params
    coin = Coin.where( symbol: ENV["COIN"] ).first
    unless coin
      puts "ERROR: Coin #{ENV['COIN']} not found."
      exit
    end
    
    token = Token.where( symbol: ENV["TOKEN"] ).first
    unless token
      puts "ERROR: Token #{ENV['TOKEN']} not found."
      exit
    end
    
    trading_pair = TradingPair.where( coin: coin, token: token ).first
    unless trading_pair
      puts "ERROR: Trading Pair #{token.symbol}#{coin.symbol} not found."
      exit
    end
    
    strategy = Strategy.where( name: ENV["STRATEGY"] ).first
    unless strategy
      puts "ERROR: Strategy #{strategy} not found."
      exit
    end
    
    coin_qty = BigDecimal.new( ENV["COIN_QTY"] )
    if coin_qty > 1
      puts "ERROR: Coin quantity cannot be 1 or higher. You can override this restriction in the Rails console."
      exit
    end
    
    buy_pct = BigDecimal.new( ENV["BUY_PCT"] )
    if buy_pct >= 1
      puts "ERROR: Buy percentage cannot be 1 or higher."
      exit
    end
    
    sell_pct = BigDecimal.new( ENV["SELL_PCT"] )
    if sell_pct >= 1
      puts "ERROR: Sell percentage cannot be 1 or higher."
      exit
    end
    
    ceiling_pct = ENV["CEILING_PCT"]
    if ceiling_pct
      ceiling_pct = BigDecimal.new( ceiling_pct )
      if ceiling_pct >= 1
        puts "ERROR: Ceiling percentage cannot be 1 or higher."
        exit
      end
    else
      ceiling_pct = 0
    end

    wait_period = ENV["WAIT_PERIOD"].to_i
    if wait_period < 60
      puts "ERROR: Wait period cannot be less than 60 minutes."
      exit
    end
    
    ## Params validated. Create bot.
    trader = Trader.create( trading_pair: trading_pair,
                            strategy: strategy, 
                            coin_qty: coin_qty,
                            original_coin_qty: coin_qty,
                            buy_pct: buy_pct,
                            sell_pct: sell_pct,
                            ceiling_pct: ceiling_pct,
                            wait_period: wait_period,
                            active: true )
    
    puts "SUCCES: Bot Created! Symbol = #{trader.trading_pair.symbol}, Initial Qty = #{trader.coin_qty.to_s} #{trader.trading_pair.coin.symbol}, Buy Pct = #{trader.buy_pct.to_s}, Sell Pct = #{trader.sell_pct.to_s}, Wait Period = #{trader.wait_period} minutes, Strategy = #{trader.strategy.name}."
    
  end

  desc 'Create bot from tokens'
  task :create_from_tokens => :environment do
    
    ## Usage:
    ## rake bots:create_from_tokens COIN=ETH TOKEN=REQ TOKEN_QTY=200 BUY_PCT=0.05 SELL_PCT=0.05 CEILING_PCT=0.05 WAIT_PERIOD=1440 STRATEGY=ALPHA
    
    puts "Creating bot..."
    
    ## Get params
    coin = Coin.where( symbol: ENV["COIN"] ).first
    unless coin
      puts "ERROR: Coin #{ENV['COIN']} not found."
      exit
    end
    
    token = Token.where( symbol: ENV["TOKEN"] ).first
    unless token
      puts "ERROR: Token #{ENV['TOKEN']} not found."
      exit
    end
    
    trading_pair = TradingPair.where( coin: coin, token: token ).first
    unless trading_pair
      puts "ERROR: Trading Pair #{token.symbol}#{coin.symbol} not found."
      exit
    end
    
    strategy = Strategy.where( name: ENV["STRATEGY"] ).first
    unless strategy
      puts "ERROR: Strategy #{strategy} not found."
      exit
    end
    
    token_qty = BigDecimal.new( ENV["TOKEN_QTY"] )
    if token_qty < 1
      puts "ERROR: Token quantity must be 1 or higher."
      exit
    end
    
    buy_pct = BigDecimal.new( ENV["BUY_PCT"] )
    if buy_pct >= 1
      puts "ERROR: Buy percentage cannot be 1 or higher."
      exit
    end
    
    sell_pct = BigDecimal.new( ENV["SELL_PCT"] )
    if sell_pct >= 1
      puts "ERROR: Sell percentage cannot be 1 or higher."
      exit
    end
    
    ceiling_pct = ENV["CEILING_PCT"]
    if ceiling_pct
      ceiling_pct = BigDecimal.new( ceiling_pct )
      if ceiling_pct >= 1
        puts "ERROR: Ceiling percentage cannot be 1 or higher."
        exit
      end
    else
      ceiling_pct = 0
    end
    
    wait_period = ENV["WAIT_PERIOD"].to_i
    if wait_period < 60
      puts "ERROR: Wait period cannot be less than 60 minutes."
      exit
    end
    
    ## Params validated. Create bot.
    trader = Trader.create( trading_pair: trading_pair,
                            strategy: strategy, 
                            token_qty: token_qty,
                            buy_pct: buy_pct,
                            sell_pct: sell_pct,
                            ceiling_pct: ceiling_pct,
                            wait_period: wait_period,
                            active: true )
    
    puts "SUCCES: Bot Created! Symbol = #{trader.trading_pair.symbol}, Initial Qty = #{trader.token_qty.to_s} #{trader.trading_pair.token.symbol}, Buy Pct = #{trader.buy_pct.to_s}, Sell Pct = #{trader.sell_pct.to_s}, Ceiling Pct = #{trader.ceiling_pct.to_s}, Wait Period = #{trader.wait_period} minutes, Strategy = #{trader.strategy.name}."
    
  end

  desc 'Create bot from tokens'
  task :create_from_tokens_with_original_qty => :environment do
    
    ## Usage:
    ## rake bots:create_from_tokens_with_original_qty COIN=ETH TOKEN=REQ TOKEN_QTY=100 BUY_PCT=0.005 SELL_PCT=0.05 CEILING_PCT=0.05 WAIT_PERIOD=1440 STRATEGY=ALPHA
    
    puts "Creating bot..."
    
    ## Get params
    coin = Coin.where( symbol: ENV["COIN"] ).first
    unless coin
      puts "ERROR: Coin #{ENV['COIN']} not found."
      exit
    end
    
    token = Token.where( symbol: ENV["TOKEN"] ).first
    unless token
      puts "ERROR: Token #{ENV['TOKEN']} not found."
      exit
    end
    
    trading_pair = TradingPair.where( coin: coin, token: token ).first
    unless trading_pair
      puts "ERROR: Trading Pair #{token.symbol}#{coin.symbol} not found."
      exit
    end
    
    strategy = Strategy.where( name: ENV["STRATEGY"] ).first
    unless strategy
      puts "ERROR: Strategy #{strategy} not found."
      exit
    end
    
    token_qty = BigDecimal.new( ENV["TOKEN_QTY"] )
    if token_qty < 1
      puts "ERROR: Token quantity must be 1 or higher."
      exit
    end
    
    buy_pct = BigDecimal.new( ENV["BUY_PCT"] )
    if buy_pct >= 1
      puts "ERROR: Buy percentage cannot be 1 or higher."
      exit
    end
    
    sell_pct = BigDecimal.new( ENV["SELL_PCT"] )
    if sell_pct >= 1
      puts "ERROR: Sell percentage cannot be 1 or higher."
      exit
    end
    
    ceiling_pct = ENV["CEILING_PCT"]
    if ceiling_pct
      ceiling_pct = BigDecimal.new( ceiling_pct )
      if ceiling_pct >= 1
        puts "ERROR: Ceiling percentage cannot be 1 or higher."
        exit
      end
    else
      ceiling_pct = 0
    end
    
    wait_period = ENV["WAIT_PERIOD"].to_i
    if wait_period < 60
      puts "ERROR: Wait period cannot be less than 60 minutes."
      exit
    end
    
    ## Get client
    api_key    = ENV['BINANCE_API_KEY']
    secret_key = ENV['BINANCE_SECRET_KEY']
    @client = Binance::Client::REST.new( api_key: api_key, secret_key: secret_key )
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    
    ## Calculate original coin qty
    twenty_four_hour = @client.twenty_four_hour( symbol: trading_pair.symbol )
    original_coin_qty = token_qty * twenty_four_hour['lastPrice'].to_f
    
    ## Params validated. Create bot.
    trader = Trader.create( trading_pair: trading_pair,
                            strategy: strategy, 
                            token_qty: token_qty,
                            original_coin_qty: original_coin_qty,
                            buy_pct: buy_pct,
                            sell_pct: sell_pct,
                            ceiling_pct: ceiling_pct,
                            wait_period: wait_period,
                            active: true )
    
    puts "SUCCES: Bot Created! Symbol = #{trader.trading_pair.symbol}, Initial Qty = #{trader.token_qty.to_s} #{trader.trading_pair.token.symbol}, Buy Pct = #{trader.buy_pct.to_s}, Sell Pct = #{trader.sell_pct.to_s}, Ceiling Pct = #{trader.ceiling_pct.to_s}, Wait Period = #{trader.wait_period} minutes, Strategy = #{trader.strategy.name}, Original Coin Qty = #{trader.original_coin_qty}."
    
  end

  desc 'Merge bots'
  task :merge => :environment do
    
    ## Usage:
    ## rake bots:merge COIN=ETH TOKEN=LINK STRATEGY=ALPHA
    
    ## Get params
    coin = Coin.where( symbol: ENV["COIN"] ).first
    unless coin
      puts "ERROR: Coin #{ENV['COIN']} not found."
      exit
    end
    
    token = Token.where( symbol: ENV["TOKEN"] ).first
    unless token
      puts "ERROR: Token #{ENV['TOKEN']} not found."
      exit
    end
    
    trading_pair = TradingPair.where( coin: coin, token: token ).first
    unless trading_pair
      puts "ERROR: Trading Pair #{token.symbol}#{coin.symbol} not found."
      exit
    end
    
    strategy = Strategy.where( name: ENV["STRATEGY"] ).first
    unless strategy
      puts "ERROR: Strategy #{strategy} not found."
      exit
    end
    
    ## Find bots to merge
    bots = Trader.where( trading_pair: trading_pair, strategy: strategy, active: true  ).to_a
    bots.each do |bot|
      ## Find siblings
      siblings = bot.siblings
      siblings.each do |sibling|
        ## Validate sibling
        if bot.sibling?( sibling )
          bot_order = bot.current_order
          next unless bot_order and bot_order.side == "BUY"
          sibling_order = sibling.current_order
          next unless sibling_order and sibling_order.side == "BUY"
          
          ## Do buy order prices match?
          if bot_order.price == sibling_order.price
            ## Merge!
            if bot.created_at < sibling.created_at
              BotTrader.merge( bot, sibling )
            else
              BotTrader.merge( sibling, bot )
            end
          end
          
          ## Exit
          exit
          
        end
      end
      
    end

  end
 
end