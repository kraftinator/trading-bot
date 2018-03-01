class Campaign < ApplicationRecord
  
  belongs_to  :user
  belongs_to  :exchange_trading_pair
  has_many    :traders
  delegate    :exchange, :to => :exchange_trading_pair
  
  validates_presence_of :user_id, :exchange_trading_pair_id, :max_price
  
  scope :active, -> { where( 'deactivated_at is null' ) }
  
  def holdings
    traders = self.traders.active
    opts = {}
    opts[:coin_amount] = opts[:profit] = opts[:original_coin_amount] = 0
    traders.each do |trader|
      opts[:coin_amount] += trader.coin_amount
      opts[:profit] += trader.profit
      opts[:original_coin_amount] += trader.original_coin_qty
    end
    opts
  end
  
  # opts[:token_holdings] = Array
  
  def total_coins_and_tokens
    coins = tokens = 0
    traders = self.traders.active
    traders.each do |trader|
      coins += trader.coin_qty
      tokens += trader.token_qty
    end
    return coins, tokens      
  end
  
  def disable
    update( deactivated_at: Time.current )
  end

  def enable
    update( deactivated_at: nil )
  end
  
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
  
  def trading_pair_display_name
    exchange_trading_pair.display_name
  end
  
end
