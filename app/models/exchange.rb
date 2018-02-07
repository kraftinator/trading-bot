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
      puts name
    end
    OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE)
    client
  end
  
  def userless_client
    case name
    when 'Binance'
      client = Binance::Client::REST.new
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
  ## API Methods
  ####################
  def query_order( opts )
    ## Get params
    client = opts[:client]
    symbol = opts[:symbol]
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
      order = client.query_order( symbol: symbol, orderId: order_id )
      ## Extract fields
      side = order['side']
      status = order['status']
      executed_qty = BigDecimal( order['executedQty'] )
      price = BigDecimal( order['price'] )
      ## Create API Order object
      api_order = ApiOrder.new( side: side, status: status, executed_qty: executed_qty, price: price )
      
    when 'Coinbase'
      ## Do nothing
    end
    
    api_order
    
  end
  
  def create_order( opts )
    ## Get params
    client = opts[:client]
    symbol = opts[:symbol]
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
      ##   "side"=>"BUY"}
      ############################################################
      
      ## Create order using API
      order = client.create_order( symbol: symbol, side: side, quantity: qty, price: price, type: 'LIMIT', timeInForce: 'GTC' )
      ## Extract fields
      uid = order['orderId']
      side = order['side']
      status = order['status']
      executed_qty = BigDecimal( order['executedQty'] )
      original_qty = BigDecimal( order['origQty'] )
      price = BigDecimal( order['price'] )
      ## Create API Order object
      api_order = ApiOrder.new( uid: uid, side: side, status: status, executed_qty: executed_qty, original_qty: original_qty, price: price )
      
    when 'Coinbase'
      ## Do nothing
    end
    
    api_order
    
  end

  def cancel_order( opts )
    ## Get params
    client = opts[:client]
    symbol = opts[:symbol]
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
      ##    "msg"=>"UNKNOWN_ORDER"} 
      ############################################################

      ## Cancel order using API
      order = client.cancel_order( symbol: symbol, orderId: order_id )
      ## Extract fields
      uid = order['orderId']
      error_code = order['code']
      error_msg = order['msg']
      ## Create API Order object
      api_order = ApiOrder.new( uid: uid, error_code: error_code, error_msg: error_msg )
      
    when 'Coinbase'
      ## Do nothing
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
      balance = asset['free']
    when 'Coinbase'
      ## Do nothing
    end
    
    balance
    
  end

end
