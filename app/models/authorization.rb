class Authorization < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :exchange
  
  validates_presence_of :user_id, :exchange_id, :api_key, :api_secret
  validates_presence_of :api_pass, if: :has_pass?
  
  def client
    exchange.api_client( self )
  end
  
  def has_pass?
    exchange.has_pass?
  end

end
