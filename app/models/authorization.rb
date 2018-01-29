class Authorization < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :exchange
  
  validates_presence_of :user_id, :exchange_id
  
  def client
    exchange.api_client( self )
  end
  
end
