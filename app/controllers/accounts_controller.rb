class AccountsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :active_required, :except => [:inactive]
  
  def index
    @holdings = current_user.holdings
    
    
    client = BotTrader.client
    twenty_four_hour = client.twenty_four_hour( symbol: 'ETHUSDT' )
    @eth_price = twenty_four_hour['lastPrice'].to_f
    
    coin_total, @token_holdings = current_user.token_holdings
    @token_holdings.each do |token_holding|
      twenty_four_hour = client.twenty_four_hour( symbol: token_holding[:trading_pair].symbol )
      token_holding[:price] = twenty_four_hour['lastPrice'].to_f
      token_holding[:eth_value] = token_holding[:token_amount] * token_holding[:price]
      token_holding[:fiat_value] = ( token_holding[:token_amount] * token_holding[:price] ) * @eth_price
    end
    
    ## Create ETH holding
    opts = {}
    opts[:eth_value] = coin_total
    opts[:fiat_value] = opts[:eth_value] * @eth_price
    
    @token_holdings << opts
    
    ## Sort token holdings 
    @token_holdings = @token_holdings.sort_by { |th| th[:eth_value] }.reverse
    
    @precision = 8
    ## Get USD value
    #client = BotTrader.client
    #twenty_four_hour = client.twenty_four_hour( symbol: 'ETHUSDT' )
    #@eth_price = twenty_four_hour['lastPrice'].to_f
    #@eth_price = 1100.00
  end
  
  def inactive
  end
  
end
