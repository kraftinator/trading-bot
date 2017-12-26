class Trader < ApplicationRecord
  
  belongs_to  :trading_pair
  belongs_to  :strategy
  has_many  :limit_orders
  
  def current_order
    limit_orders.where( open: true ).first
  end
  
  def coin_amount
    order = current_order
    if order and order.side == 'SELL'
      buy_order = order.buy_order
      coin_qty + ( buy_order.price * buy_order.qty )
    else
      coin_qty
    end
  end
  
  def fiat_amount( exchange_rate )
    coin_amount * exchange_rate
  end
  
  def profit
    coin_amount - 0.05
  end
  
  def fiat_profit( exchange_rate )
    profit * exchange_rate
  end

end
