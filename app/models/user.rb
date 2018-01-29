class User < ApplicationRecord

  has_many  :authorizations
  has_many  :traders
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         

  def holdings
    trading_pairs = TradingPair.with_active_traders
    opts = {}
    opts[:coin_amount] = opts[:profit] = opts[:original_coin_amount] = 0
    trading_pairs.each do |trading_pair|
      opts[:coin_amount] += trading_pair.holdings[:coin_amount]
      opts[:profit] += trading_pair.holdings[:profit]
      opts[:original_coin_amount] += trading_pair.holdings[:original_coin_amount]
    end
    opts
  end
  
  def token_holdings
    results = []
    coin_total = 0
    trading_pairs = TradingPair.with_active_traders
    trading_pairs.each do |trading_pair|
      opts = {}
      opts[:trading_pair] = trading_pair
      coins, tokens = trading_pair.total_coins_and_tokens
      coin_total += coins
      opts[:token_amount] = tokens
      results << opts
    end
    return coin_total, results
  end
  
  def partially_filled_orders
    pfos = []
    traders.each { |t| pfos << t.current_order.partially_filled_order if t.current_order and t.current_order.partially_filled_order }
    pfos
  end
  
end
