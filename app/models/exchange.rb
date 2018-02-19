require './lib/api_order.rb'

class Exchange < ApplicationRecord
  
  has_many  :authorizations
  has_many  :coins, :class_name => "ExchangeCoin"
  has_many  :trading_pairs, :class_name => "ExchangeTradingPair"
  
  default_scope { order('name asc') }
  
  def api_client( authorization )
    case name
    when 'Binance'
      client = Binance::Client::REST.new( api_key: authorization.api_key, secret_key: authorization.api_secret )
    when 'Coinbase'
      client = Coinbase::Exchange::Client.new( authorization.api_key, authorization.api_secret, authorization.api_pass )
    end
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    client
  end
  
  def userless_client
    case name
    when 'Binance'
      client = Binance::Client::REST.new
    when 'Coinbase'
      client = Coinbase::Exchange::Client.new
    end
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    client
  end
  
  def authorization( user )
    authorization = self.authorizations.where( user: user ).first
  end
  
  def has_pass?
    name == 'Coinbase'
  end
  
  ####################
  ## Userless API Methods
  ####################
  
  def fiat_stats( base_coin )
    ## Choose API
    case name
    when 'Binance'
      #coin1 = coins.where( symbol: 'ETH' ).first
      coin1 = base_coin
      coin2 = coins.where( symbol: 'USDT' ).first
      trading_pair = trading_pairs.where( coin1: coin1, coin2: coin2 ).first
      trading_pair.load_stats
      stats = trading_pair.stats
    when 'Coinbase'
      #coin1 = coins.where( symbol: 'ETH' ).first
      coin1 = base_coin
      coin2 = coins.where( symbol: 'USD' ).first
      trading_pair = trading_pairs.where( coin1: coin1, coin2: coin2 ).first
      trading_pair.load_stats
      stats = trading_pair.stats
    end
    stats
  end
  
  ####################
  ## User API Methods
  ####################
  
  def query_order( opts )
    ## Get params
    client = opts[:client]
    trading_pair = opts[:trading_pair]
    order_id = opts[:order_id]
    ## Choose API
    case name
    when 'Binance'
      
      ############################################################
      ## Binance API query_order result:
      ##    "symbol"=>"REQETH", 
      ##    "orderId"=>2910164, 
      ##    "clientOrderId"=>"jSpBQBvcldXTAx5NKN4wfz", 
      ##    "price"=>"0.00036471", 
      ##    "origQty"=>"137.00000000", 
      ##    "executedQty"=>"0.00000000", 
      ##    "status"=>"CANCELED", 
      ##    "timeInForce"=>"GTC", 
      ##    "type"=>"LIMIT", 
      ##    "side"=>"BUY", 
      ##    "stopPrice"=>"0.00000000", 
      ##    "icebergQty"=>"0.00000000", 
      ##    "time"=>1513985250681, 
      ##    "isWorking"=>true} 
      ############################################################
      
      ## Query order using API
      order = client.query_order( symbol: trading_pair.symbol, orderId: order_id )
      
      ## Extract fields
      unless order['code']
        side = order['side']
        status = order['status']
        executed_qty = BigDecimal( order['executedQty'] )
        price = BigDecimal( order['price'] )
        ## Create API Order object
        api_order = ApiOrder.new( side: side, status: status, executed_qty: executed_qty, price: price )
      else
        error_code = order['code']
        error_msg = order['msg']
        ## Create API order
        api_order = ApiOrder.new( error_code: error_code, error_msg: error_msg )
      end
      
    when 'Coinbase'
      
      ############################################################
      ## Coinbase API query_order result:
      ##   "id"=>"7360fd93-a488-41bc-8d23-35c7d493da8e", 
      ##   "price"=>"931.01000000", 
      ##   "size"=>"0.02000000", 
      ##   "product_id"=>"ETH-USD", 
      ##   "side"=>"sell", 
      ##   "type"=>"limit", 
      ##   "time_in_force"=>"GTC", 
      ##   "post_only"=>false, 
      ##   "created_at"=>"2018-02-15T22:53:16.55265Z", 
      ##   "done_at"=>"2018-02-15T22:55:24.698Z", 
      ##   "done_reason"=>"filled", 
      ##   "fill_fees"=>"0.0000000000000000", 
      ##   "filled_size"=>"0.02000000", 
      ##   "executed_value"=>"18.6202000000000000", 
      ##   "status"=>"done", 
      ##   "settled"=>true
      ############################################################

      order_canceled = false
      
      ## Query order using API
      begin
        client.order( order_id ) do |resp|
          order = resp
        end
      rescue Coinbase::Exchange::NotFoundError
        error_msg = $!
        order_canceled = true
      rescue
        error_msg = $!
      end
      
      ## Exctract fields
      unless error_msg
        side = order.side.upcase
        executed_qty = BigDecimal( order.filled_size )
        price = BigDecimal( order.price )
        ## Determine status
        case order.status
        when 'open'
          if order.filled_size == 0
            status = 'NEW'
          else
            status = 'PARTIALLY_FILLED'
          end
        when 'done'
          status = 'FILLED'
        end
        ## Create API Order object
        api_order = ApiOrder.new( side: side, status: status, executed_qty: executed_qty, price: price )
      else
        if order_canceled
          api_order = ApiOrder.new( status: 'CANCELED' )
        else
          api_order = ApiOrder.new( error_msg: error_msg )
        end
      end
      
    end
    
    api_order
    
  end
  
  def create_order( opts )
    ## Get params
    client = opts[:client]
    trading_pair = opts[:trading_pair]
    side = opts[:side]
    qty = opts[:qty]
    price = opts[:price]
    ## Choose API
    case name
    when 'Binance'
      
      ############################################################
      ## Binance API create order result:
      ##   "symbol"=>"LINKETH", 
      ##   "orderId"=>8425459, 
      ##   "clientOrderId"=>"r1i13cJiPYtp28NlAIO44l", 
      ##   "transactTime"=>1518024238840, 
      ##   "price"=>"0.00036471", 
      ##   "origQty"=>"50.00000000", 
      ##   "executedQty"=>"0.00000000", 
      ##   "status"=>"NEW", 
      ##   "timeInForce"=>"GTC", 
      ##   "type"=>"LIMIT", 
      ##   "side"=>"BUY
      ##
      ## Binance API create order failed results
      ##   "code"=>-1021, 
      ##   "msg"=>"Timestamp for this request was 1000ms ahead of the server's time."
      ############################################################
      
      ## Create order using API
      order = client.create_order( symbol: trading_pair.symbol, side: side, quantity: qty, price: price, type: 'LIMIT', timeInForce: 'GTC' )
      
      ## Extract fields
      unless order['code']
        uid = order['orderId']
        side = order['side']
        status = order['status']
        executed_qty = BigDecimal( order['executedQty'] )
        original_qty = BigDecimal( order['origQty'] )
        price = BigDecimal( order['price'] )
        ## Create API order
        api_order = ApiOrder.new( uid: uid, side: side, status: status, executed_qty: executed_qty, original_qty: original_qty, price: price )
      else
        error_code = order['code']
        error_msg = order['msg']
        ## Create API order
        api_order = ApiOrder.new( error_code: error_code, error_msg: error_msg )
      end
        
    when 'Coinbase'
      
      ############################################################
      ## Coinbase API create order result:
      ##   "id"=>"deeebbad-0e08-4c83-acfe-aa25c61de2a7", 
      ##   "price"=>"2000.00000000", 
      ##   "size"=>"0.02000000", 
      ##   "product_id"=>"ETH-USD", 
      ##   "side"=>"sell", 
      ##   "stp"=>"dc", 
      ##   "type"=>"limit", 
      ##   "time_in_force"=>"GTC", 
      ##   "post_only"=>false, 
      ##   "created_at"=>"2018-02-14T17:55:56.219308Z", 
      ##   "fill_fees"=>"0.0000000000000000", 
      ##   "filled_size"=>"0.00000000", 
      ##   "executed_value"=>"0.0000000000000000", 
      ##   "status"=>"pending", 
      ##   "settled"=>false
      ############################################################
      
      order = nil
      
      ## Create order using API
      if side == 'BUY'
        begin
          client.buy( qty, price, { "product_id": "#{trading_pair.coin1.symbol}-#{trading_pair.coin2.symbol}" } ) do |resp|
            order = resp
          end
        rescue
          error_msg = $!
        end
      elsif side == 'SELL'
        begin
          client.sell( qty, price, { "product_id": "#{trading_pair.coin1.symbol}-#{trading_pair.coin2.symbol}" } ) do |resp|
            order = resp
          end
        rescue
          error_msg = $!
        end
      end
      
      unless error_msg
        uid = order.id
        side = order.side.upcase
        status = 'NEW'
        executed_qty = BigDecimal( order.executed_value )
        original_qty = BigDecimal( order.size )
        price = BigDecimal( order.price )
        ## Create API order
        api_order = ApiOrder.new( uid: uid, side: side, status: status, executed_qty: executed_qty, original_qty: original_qty, price: price )
      else
        ## Create API order
        api_order = ApiOrder.new( error_msg: error_msg )
      end
      
    end
    
    api_order
    
  end

  def cancel_order( opts )
    ## Get params
    client = opts[:client]
    trading_pair = opts[:trading_pair]
    order_id = opts[:order_id]
    ## Choose API
    case name
    when 'Binance'
      
      ############################################################
      ## Binance API cancel_order successful result:
      ##    "symbol"=>"LINKETH", 
      ##    "origClientOrderId"=>"oKEUwJmqlfBuijAdfCrqfG", 
      ##    "orderId"=>8428361, 
      ##    "clientOrderId"=>"NiBgDmeCqXPn1sTKWULA66"} 
      ##
      ## Binance API cancel_order failed result:
      ##    "code"=>-2011, 
      ##    "msg"=>"UNKNOWN_ORDER"
      ############################################################

      ## Cancel order using API
      order = client.cancel_order( trading_pair: trading_pair.symbol, orderId: order_id )
      ## Extract fields
      unless order['code']
        uid = order['orderId']
        ## Create API order
        api_order = ApiOrder.new( uid: uid )
      else
        error_code = order['code']
        error_msg = order['msg']
        ## Create API order
        api_order = ApiOrder.new( error_code: error_code, error_msg: error_msg )
      end
      
    when 'Coinbase'
      
      ## Coinbase API returns nothing if cancellation is successful.
      begin
        client.cancel( order_id ) do |resp|
          order = resp
        end
      rescue
        error_msg = $!
      end
      
      unless error_msg
        ## Create API order
        api_order = ApiOrder.new
      else
        ## Create API order
        api_order = ApiOrder.new( error_msg: error_msg )
      end

    end
    
    api_order
    
  end
  
  def coin_balance( opts )
    ## Get params
    client = opts[:client]
    coin = opts[:coin]
    ## Choose API
    case name
    when 'Binance'
      account_info = client.account_info
      balances = account_info['balances']
      asset = balances.select { |b| b['asset'] == coin.symbol }.first
      balance = BigDecimal( asset['free'] )
    when 'Coinbase'
      accounts = client.accounts
      account = accounts.select { |a| a['currency'] == coin.symbol }.first
      balance = BigDecimal( account['available'] )
    end
    
    balance
    
  end

end
