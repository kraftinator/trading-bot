class LimitOrder < ApplicationRecord
  
  belongs_to  :trader
  
  def buy_order
    return nil if side == 'BUY'
    self.where( side: 'BUY', trader: trader ).order( 'created_at desc' ).first
  end
  
end
