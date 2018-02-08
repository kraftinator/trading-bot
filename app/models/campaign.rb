class Campaign < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :exchange_trading_pair
  has_many    :traders
  delegate    :exchange, :to => :exchange_trading_pair
  
  scope :active, -> { where( 'deactivated_at is null' ) }
  
  def active?
    deactivated_at.nil?
  end
  
  def client
    authorization = user.authorization( exchange )
    authorization.client
  end
  
  def symbol
    exchange_trading_pair.symbol
  end
  
end
