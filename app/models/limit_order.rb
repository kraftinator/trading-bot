class LimitOrder < ApplicationRecord
  
  belongs_to  :trader
  has_one     :partially_filled_order
  
  scope :partially_filled, -> { partially_filled? }
  
  ## constants
  STATES = { new: "NEW", canceled: "CANCELED", filled: "FILLED", partially_filled: "PARTIALLY_FILLED" }
  
  def buy_order
    return nil if side == 'BUY'
    LimitOrder.where( side: 'BUY', trader: trader ).order( 'created_at desc' ).first
  end
  
  def partially_filled?
    partially_filled_order
  end
  
  
  
end
