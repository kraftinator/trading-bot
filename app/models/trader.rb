class Trader < ApplicationRecord
  
  belongs_to  :trading_pair
  belongs_to  :strategy
  has_many  :limit_orders
  
  def current_order
    limit_orders.where( open: true ).first
  end
  
  def coin_amount
    order = current_order
    return 0 unless order
  end
  
end
