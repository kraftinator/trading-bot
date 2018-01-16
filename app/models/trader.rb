class Trader < ApplicationRecord
  
  belongs_to  :trading_pair
  belongs_to  :strategy
  has_many  :limit_orders

  belongs_to :merged_trader, :class_name => "Trader", optional: true
  has_many :children, :class_name => "Trader", :foreign_key => "merged_trader_id"
  
  def current_order
    limit_orders.where( open: true ).first
  end
  
  def siblings
    traders = Trader.where( trading_pair: trading_pair, strategy: strategy, buy_pct: buy_pct, sell_pct: sell_pct, ceiling_pct: ceiling_pct, wait_period: wait_period, active: active ).to_a
    traders.delete( self )
    traders
  end
  
  def sibling?( sibling )
    trading_pair == sibling.trading_pair && strategy == sibling.strategy && buy_pct == sibling.buy_pct && sell_pct == sibling.sell_pct && ceiling_pct = sibling.ceiling_pct && wait_period == sibling.wait_period
  end
  
  def last_fulfilled_order
    limit_orders.where( open: false ).order( 'created_at desc' ).first
  end
  
  def show_last_fulfilled_order_date
    order = last_fulfilled_order
    return order.updated_at if order
    #nil
    1.year.ago
  end
  
  def coin_amount
    order = current_order
    if order and order.side == 'SELL' and limit_orders.size > 1
      buy_order = order.buy_order
      coin_qty + ( buy_order.price * buy_order.qty )
    else
      coin_qty
    end
  end
  
  def fiat_amount( exchange_rate )
    coin_amount * exchange_rate
  end
  
  def formatted_fiat_amount( exchange_rate )
    amount = fiat_amount( exchange_rate )
    amount = '%.2f' % amount
    '$' + amount
  end
  
  def profit
    coin_amount - original_coin_qty
  end
  
  def fiat_profit( exchange_rate )
    profit * exchange_rate
  end
  
  def formatted_fiat_profit( exchange_rate )
    amount = fiat_profit( exchange_rate )
    amount = '%.2f' % amount
    '$' + amount
  end

end
