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
require './lib/omicron_strategy.rb'
require './lib/pi_strategy.rb'
require './lib/sigma_strategy.rb'
require './lib/mu_strategy.rb'

## New strategies
require './lib/strategies/test_strategy.rb'
require './lib/strategies/alpha_strategy_new.rb' 
require './lib/strategies/beta_strategy_new.rb' 
require './lib/strategies/gamma_strategy_new.rb' 
require './lib/strategies/delta_strategy_new.rb' 
require './lib/strategies/epsilon_strategy_new.rb'
require './lib/strategies/zeta_strategy_new.rb'
require './lib/strategies/eta_strategy_new.rb'
require './lib/strategies/theta_strategy_new.rb'
require './lib/strategies/iota_strategy_new.rb'
require './lib/strategies/kappa_strategy_new.rb'
require './lib/strategies/lambda_strategy_new.rb'
require './lib/strategies/omicron_strategy_new.rb'
require './lib/strategies/pi_strategy_new.rb'
require './lib/strategies/sigma_strategy_new.rb'

module BotTrader

  module_function
  
  TradingPairStatus = Struct.new( :last_price, :weighted_avg_price, :high_price, :low_price, :bid_total, :ask_total, :price_change_pct )
  EthStatus = Struct.new( :bid_total, :ask_total, :price_change_pct, :last_price )
  
  ## Set client
  def set_client
    api_key    = ENV['BINANCE_API_KEY']
    secret_key = ENV['BINANCE_SECRET_KEY']
    @client = Binance::Client::REST.new( api_key: api_key, secret_key: secret_key )
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
  end
  
  def client
    set_client
    @client
  end
  
  ##################################################
  ##################################################
  ## New code
  def process_user( user )
    ## Get campaigns
    campaigns = user.campaigns.active
    campaigns.each do |campaign|
      traders = campaign.traders.active
      if traders.any?
        ## Get stats
        trading_pair = campaign.exchange_trading_pair
        trading_pair.load_stats
        ## Get client
        client = campaign.client
        ## If campaign's max price > 24 hour high price, keep processing
        if campaign.max_price > trading_pair.stats.high_price
          ## Process bots
          traders.each do |trader|
            strategy_class = strategy_class( trader.strategy )
            if strategy_class
              strategy = strategy_class.new( client: client, trader: trader )
              strategy.process
            else
              puts "ERROR: Invalid strategy - #{trader.strategy.name}."
            end
          end
        else
          ## Freeze bots!
          puts "WARNING: Max price reached. High price #{trading_pair.stats.high_price} > max price #{campaign.max_price.to_f}."
          traders.each do |trader|
            if trader.current_order and trader.current_order.side == 'BUY'
              trader.cancel_current_order
            end
            trader.disable
            puts "Bot #{trader.id} deactivated."
          end
          campaign.disable
          puts "Campaign #{campaign.exchange.name} #{campaign.symbol} deactivated."
        end
      end
    end
  end

  def strategy_class( strategy )
    case strategy.name
    when 'ALPHA'
      strategy_class = AlphaStrategyNew
    when 'BETA'
      strategy_class = BetaStrategyNew
    when 'GAMMA'
      strategy_class = GammaStrategyNew
    when 'DELTA'
      strategy_class = DeltaStrategyNew
    when 'EPSILON'
      strategy_class = EpsilonStrategyNew
    when 'ZETA'
      strategy_class = ZetaStrategyNew
    when 'ETA'
      strategy_class = EtaStrategyNew
    when 'THETA'
      strategy_class = ThetaStrategyNew
    when 'IOTA'
      strategy_class = IotaStrategyNew
    when 'KAPPA'
      strategy_class = KappaStrategyNew
    when 'LAMBDA'
      strategy_class = LambdaStrategyNew
    when 'OMICRON'
      strategy_class = OmicronStrategyNew
    when 'PI'
      strategy_class = PiStrategyNew
    when 'SIGMA'
      strategy_class = SigmaStrategyNew
    when 'TEST'
      strategy_class = TestStrategy
    end
    strategy_class
  end
  
  ##################################################
  ##################################################
  
  def load_eth_status
    twenty_four_hour = @client.twenty_four_hour( symbol: 'ETHUSDT' )
    depth = @client.depth( symbol: 'ETHUSDT' )
    ## Calculate bid total
    bids = depth['bids']
    bid_total = 0
    bids.each { |b| bid_total += b[0].to_f * b[1].to_f }
    ## Calculate ask total
    asks = depth['asks']
    ask_total = 0
    asks.each { |a| ask_total += a[0].to_f * a[1].to_f }
    ## Create 
    EthStatus.new( bid_total, ask_total, twenty_four_hour['priceChangePercent'].to_f, twenty_four_hour['lastPrice'].to_f )
  end
  
  def trading_pair_status( trading_pair )
    ## Get 24 hour trading stats
    twenty_four_hour = @client.twenty_four_hour( symbol: trading_pair.symbol )
    ## Get depth chart
    depth = @client.depth( symbol: trading_pair.symbol )
    ## Calculate bid total
    bids = depth['bids']
    bid_total = 0
    bids.each { |b| bid_total += b[0].to_f * b[1].to_f }
    ## Calculate ask total
    asks = depth['asks']
    ask_total = 0
    asks.each { |a| ask_total += a[0].to_f * a[1].to_f }
    ## Create Trading Pair Status sctruct
    TradingPairStatus.new( twenty_four_hour['lastPrice'].to_f, twenty_four_hour['weightedAvgPrice'].to_f, twenty_four_hour['highPrice'].to_f, twenty_four_hour['lowPrice'].to_f, bid_total, ask_total, twenty_four_hour['priceChangePercent'].to_f )
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
      strategy = AlphaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'BETA'
      strategy = BetaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'GAMMA'
      strategy = GammaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'DELTA'
      strategy = DeltaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'EPSILON'
      strategy = EpsilonStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'ZETA'
      strategy = ZetaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'ETA'
      strategy = EtaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'THETA'
      strategy = ThetaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'IOTA'
      strategy = IotaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'KAPPA'
      strategy = KappaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'LAMBDA'
      strategy = LambdaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'OMICRON'
      strategy = OmicronStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'PI'
      strategy = PiStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'SIGMA'
      strategy = SigmaStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
    when 'MU'
      strategy = MuStrategy.new( client: @client, tps: @tps, trader: trader, eth_status: @eth_status )
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
        ## Load ETH status
        @eth_status = load_eth_status
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
      when 'OMICRON'
        strategy = OmicronStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision )
      when 'PI'
        strategy = PiStrategy.new( client: @client, tps: @tps, trader: trader, precision: @precision, eth_status: @eth_status )
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
      puts "WARNING: Bot1 (#{bot1.id}) current order is not a BUY side."
      exit
    end
    
    ## Move bot2's coin quantities to bot1
    bot1.update( coin_qty: bot1.coin_qty + bot2.coin_qty, original_coin_qty: bot1.original_coin_qty + bot2.original_coin_qty )
    puts "Bot2 (#{bot2.id}) coins transferred to Bot1 (#{bot1.id})."
    
    puts "Successfully merged #{bot1.id} and #{bot2.id}!"
    
  end
      
end