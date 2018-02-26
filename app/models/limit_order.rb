class LimitOrder < ApplicationRecord
  
  belongs_to  :trader
  has_one     :partially_filled_order
  
  scope :partially_filled, -> { partially_filled? }
  #scope :filled, -> { where( "filled_at is not null" ) }
  scope :filled, -> { where( "filled_at is not null or state = 'FILLED'" ) }
  
  ## constants
  STATES = { new: "NEW", canceled: "CANCELED", filled: "FILLED", partially_filled: "PARTIALLY_FILLED" }
  
  def buy_order
    return nil if side == 'BUY'
    LimitOrder.where( side: 'BUY', trader: trader ).order( 'created_at desc' ).first
  end
  
  def previous_order
    return nil unless filled?
    trader.limit_orders.filled.where( "created_at < '#{created_at}'" ).order( 'created_at desc' ).first
  end
  
  def partially_filled?
    partially_filled_order
  end
  
  def filled?
    !filled_at.nil? || state == 'FILLED'
  end
  
end
