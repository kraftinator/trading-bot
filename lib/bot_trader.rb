require './lib/alpha_strategy.rb' 
require './lib/beta_strategy.rb' 
require './lib/gamma_strategy.rb' 
require './lib/delta_strategy.rb' 
require './lib/epsilon_strategy.rb'
require './lib/zeta_strategy.rb'
require './lib/eta_strategy.rb'
require './lib/theta_strategy.rb'
require './lib/iota_strategy.rb'
require './lib/kappa_strategy.rb'
require './lib/lambda_strategy.rb'

module BotTrader

  module_function
  
  TradingPairStatus = Struct.new( :last_price, :weighted_avg_price, :high_price, :low_price )
  
  ## Set client
  def set_client
    api_key    = ENV['BINANCE_API_KEY']
    secret_key = ENV['BINANCE_SECRET_KEY']
    @client = Binance::Client::REST.new( api_key: api_key, secret_key: secret_key )
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
  end
  
  def trading_pair_status( trading_pair )
    twenty_four_hour = @client.twenty_four_hour( symbol: trading_pair.symbol )
    TradingPairStatus.new( twenty_four_hour['lastPrice'].to_f, twenty_four_hour['weightedAvgPrice'].to_f, twenty_four_hour['highPrice'].to_f, twenty_four_hour['lowPrice'].to_f )
  end
  
  def freeze_trader( trader )
    if trader.current_order and trader.current_order.side == 'BUY'
      ## Get local limit order
      limit_order = trader.current_order
      ## Cancel order
      result = @client.cancel_order( symbol: trader.trading_pair.symbol, orderId: limit_order.order_guid )
      if result['code']
        puts "ERROR: #{result['code']} #{result['msg']}" 
      else
        puts "Order #{limit_order.order_guid} canceled."
      end
      ## Cancel local limit order
      limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
    end
    ## Deactivate trader
    trader.update( active: false )
    puts "Bot #{trader.id} deactivated."
  end
  
  def load_strategy( trader )
    strategy = nil
    case trader.strategy.name
    when 'ALPHA'
      strategy = AlphaStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'BETA'
      strategy = BetaStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'GAMMA'
      strategy = GammaStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'DELTA'
      strategy = DeltaStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'EPSILON'
      strategy = EpsilonStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'ZETA'
      strategy = ZetaStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'ETA'
      strategy = EtaStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'THETA'
      strategy = ThetaStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'IOTA'
      strategy = IotaStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'KAPPA'
      strategy = KappaStrategy.new( client: @client, tps: @tps, trader: trader )
    when 'LAMBDA'
      strategy = LambdaStrategy.new( client: @client, tps: @tps, trader: trader )
    end
    strategy
  end
  
  ## Process all active bots
  def process_all
    ## Set client
    set_client
    ## Get all trading pairs
    trading_pairs = TradingPair.all.to_a
    ## Process each trading pair
    trading_pairs.each do |trading_pair|
      ## Get bots
      traders = Trader.where( trading_pair: trading_pair, active: true ).to_a
      if traders.any?
        ## Load 24 hour trading pair stats
        @tps = trading_pair_status( trading_pair )
        ## Has max ratio been reached?
        if trading_pair.max_price.to_f < @tps[:high_price]
          ## Freeze bots!
          puts "WARNING: Max price reached. High price #{ @tps[:high_price]} > max price #{trading_pair.max_price.to_f}."
          traders.each do |trader|
            freeze_trader( trader )
          end
        else
          traders.each do |trader|
            strategy = load_strategy( trader )
            if strategy
              strategy.process
            else
              puts "ERROR: Invalid strategy - #{trader.strategy.name}."
            end
          end
        end
      end ## Any traders?
    end ## Loop over trading pairs
  end
  
  def process_trader( trader )
    set_client
    @tps = trading_pair_status( trader.trading_pair )
    strategy = load_strategy( trader )
    if strategy
      strategy.process
    else
      puts "ERROR: Invalid strategy - #{trader.strategy.name}."
    end
  end
  
  ## Test methods
  def process_test
    
    ## Client
    puts "Test client"
    set_client
    puts @client.account_info
    
    ## Trading pairs
    puts "Test trading pairs"
    trading_pairs = TradingPair.all.to_a
    puts "#{trading_pairs.size} trading pairs found"
    
    ## Trading Pair Status
    puts 'Test trading pair status'
    trading_pair = nil
    trading_pairs.each do |tp|
      traders = Trader.where( trading_pair: tp, active: true ).to_a
      if traders.any?
        trading_pair = tp
        break
      end
    end
    tps = trading_pair_status( trading_pair )
    puts "Trading pair: #{trading_pair.symbol}"
    puts tps
    
    ## Is max_price exceeded?
    if trading_pair.max_price.to_f < tps[:high_price]
      puts "Yes, price exceeded"
    else
      puts "No, price not exceeded."
    end
    
    ## Strategies
    puts "Test strategies"
    traders = Trader.where( trading_pair: trading_pair, active: true ).to_a
    traders.each do |trader|
      strategy = load_strategy( trader )
      puts strategy.class
    end
    
  end
  
  def process( trading_pair )
    
    ## Get client
    api_key    = ENV['BINANCE_API_KEY']
    secret_key = ENV['BINANCE_SECRET_KEY']
    @client = Binance::Client::REST.new( api_key: api_key, secret_key: secret_key )
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    
    ## Run bots
    traders = Trader.where( trading_pair: trading_pair, active: true ).to_a
    
    ## Any active bots found?
    if traders.any?
      ## Set precision
      #@precision = 8
      @precision = trading_pair.precision
      ## Load 24 hour trading pair stats.
      twenty_four_hour = @client.twenty_four_hour( symbol: trading_pair.symbol )
      @tps = TradingPairStatus.new( twenty_four_hour['lastPrice'].to_f, twenty_four_hour['weightedAvgPrice'].to_f, twenty_four_hour['highPrice'].to_f, twenty_four_hour['lowPrice'].to_f )
    else
      puts "No active bots found."
      return false
    end
    
    ## Has max ratio been reached?
    if trading_pair.max_price.to_f < @tps[:high_price]
      ## Freeze bots!
      puts "WARNING: Max price reached. High price #{ @tps[:high_price]} > max price #{trading_pair.max_price.to_f}."
      traders.each do |trader|
        if trader.current_order and trader.current_order.side == 'BUY'
          ## Get local limit order
          limit_order = trader.current_order
          ## Cancel order
          result = @client.cancel_order( symbol: trader.trading_pair.symbol, orderId: limit_order.order_guid )
          if result['code']
            puts "ERROR: #{result['code']} #{result['msg']}" 
          else
            puts "Order #{limit_order.order_guid} canceled."
          end
          ## Cancel local limit order
          limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
        end
        ## Deactivate trader
        trader.update( active: false )
        puts "Bot #{trader.id} deactivated."
      end
      return false
    end
    
    traders.each do |trader|
      case trader.strategy.name
      when 'ALPHA'
        strategy = AlphaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'BETA'
        strategy = BetaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'GAMMA'
        strategy = GammaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'DELTA'
        strategy = DeltaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'EPSILON'
        strategy = EpsilonStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'ZETA'
        strategy = ZetaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'ETA'
        strategy = EtaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'THETA'
        strategy = ThetaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'IOTA'
        strategy = IotaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'KAPPA'
        strategy = KappaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'LAMBDA'
        strategy = LambdaStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      else
        puts "ERROR: Invalid strategy - #{trader.strategy.name}."
        next
      end
      strategy.process
    end
    
  end ## process
  
  def merge( bot1, bot2 )
    
    ## Get client
    api_key    = ENV['BINANCE_API_KEY']
    secret_key = ENV['BINANCE_SECRET_KEY']
    @client = Binance::Client::REST.new( api_key: api_key, secret_key: secret_key )
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    
    ## Deactivate bot2's current order
    if bot2.current_order and bot2.current_order.side == 'BUY'
      ## Get local limit order
      limit_order = bot2.current_order
      ## Cancel order
      result = @client.cancel_order( symbol: bot2.trading_pair.symbol, orderId: limit_order.order_guid )
      if result['code']
        puts "ERROR: #{result['code']} #{result['msg']}" 
      else
        puts "Order #{limit_order.order_guid} canceled."
      end
      ## Cancel local limit order
      limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
    else
      puts "WARNING: Bot2 (#{bot2.id}) current order is not a BUY side."
      exit
    end
    
    ## Deactivate bot2
    bot2.update( active: false, merged_at: Time.current, merged_trader: bot1 )
    puts "Bot2 (#{bot2.id}) deactivated and merged."
    
    ## Deactivate bot1's current order
    if bot1.current_order and bot1.current_order.side == 'BUY'
      ## Get local limit order
      limit_order = bot1.current_order
      ## Cancel order
      result = @client.cancel_order( symbol: bot1.trading_pair.symbol, orderId: limit_order.order_guid )
      if result['code']
        puts "ERROR: #{result['code']} #{result['msg']}" 
      else
        puts "Order #{limit_order.order_guid} canceled."
      end
      ## Cancel local limit order
      limit_order.update( open: false, state: LimitOrder::STATES[:canceled] )
    else
      puts "WARNING: Bot2 (#{bot1.id}) current order is not a BUY side."
      exit
    end
    
    ## Move bot2's coin quantities to bot1
    bot1.update( coin_qty: bot1.coin_qty + bot2.coin_qty, original_coin_qty: bot1.original_coin_qty + bot2.original_coin_qty )
    puts "Bot2 (#{bot2.id}) coins transferred to Bot1 (#{bot1.id})."
    
    puts "Successfully merged #{bot1.id} and #{bot2.id}!"
    
  end
      
end