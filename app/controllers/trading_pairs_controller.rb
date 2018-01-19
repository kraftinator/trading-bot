class TradingPairsController < ApplicationController
  
  before_action :set_trading_pair, only: [:show, :edit]
  
  def edit
  end

  def index
     @trading_pairs = TradingPair.all.to_a.sort_by( &:symbol )
  end

  def new
  end

  def show
    @traders = @trading_pair.traders.active.to_a.sort_by( &:show_last_fulfilled_order_date ).reverse
  end
  
  private
  
  def set_trading_pair
    @trading_pair = TradingPair.find( params[:id] )
  end
  
end
