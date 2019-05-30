class IndexFundCoinsController < ApplicationController
  
  before_action :set_index_fund_coin, only: [:show, :edit, :update, :destroy]
  before_action :load_index_fund_coin_attributes, only: [:edit]

  def new
    index_fund = IndexFund.find(params[:index_fund_id])
    @index_fund_coin = IndexFundCoin.new(index_fund: index_fund, allocation_pct: 0)
    @exchange_trading_pairs = ExchangeTradingPair.where(coin2: index_fund.base_coin).sort_by(&:coin1_symbol)
  end
  
  def create
    @index_fund_coin = IndexFundCoin.new(index_fund_coin_params)
    if @index_fund_coin.save
      redirect_to edit_index_fund_path(@index_fund_coin.index_fund)
    else
      flash.now[:alert] = @index_fund_coin.errors.full_messages.to_sentence
      load_index_fund_coin_attributes
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @index_fund_coin.update(index_fund_coin_params)
      redirect_to edit_index_fund_path(@index_fund_coin.index_fund)
    else
      flash.now[:alert] = @index_fund_coin.errors.full_messages.to_sentence
      load_index_fund_coin_attributes
      render :edit
    end
  end
  
  def destroy
    index_fund = @index_fund_coin.index_fund
    @index_fund_coin.destroy
    redirect_to edit_index_fund_path(index_fund)
  end
  
  private
  
  def index_fund_coin_params
    params.require(:index_fund_coin).permit(:index_fund_id, :exchange_trading_pair_id, :allocation_pct)
  end
  
  def load_index_fund_coin_attributes
    @exchange_trading_pairs = ExchangeTradingPair.where(coin2: @index_fund_coin.index_fund.base_coin).sort_by(&:coin1_symbol)
  end
  
  def set_index_fund_coin
    @index_fund_coin = IndexFundCoin.find(params[:id])
  end
  
end
