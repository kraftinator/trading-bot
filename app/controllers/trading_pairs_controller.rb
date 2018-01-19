class TradingPairsController < ApplicationController
  
  def edit
  end

  def index
     @trading_pairs = TradingPair.all.to_a.sort_by( &:symbol )
  end

  def new
  end

  def show
  end
  
end
