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
    client
  end
  
  def authorization( user )
    authorization = self.authorizations.where( user: user )
  end
  
  def has_pass?
    name == 'Coinbase'
  end

end
