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

module BotTrader

  module_function
  
  TradingPairStatus = Struct.new( :last_price, :weighted_avg_price, :high_price, :low_price )
  
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
          limit_order.update( open: false )
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
      else
        puts "ERROR: Invalid strategy - #{trader.strategy.name}."
        next
      end
      strategy.process
    end
    
  end ## process
      
end