class Exchange < ApplicationRecord
  
  has_many  :authorizations
  
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
  
  def binance?
    name == 'Binance'
  end
  
  def coinbase?
    name == 'Coinbase'
  end
  
end
