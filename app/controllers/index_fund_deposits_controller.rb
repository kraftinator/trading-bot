class IndexFundDepositsController < ApplicationController
  
  def new
    index_fund_coin = IndexFundCoin.find(params[:index_fund_coin_id])
    @deposit = IndexFundDeposit.new(index_fund_coin: index_fund_coin, qty: 0)
  end
  
  def create
    @deposit = IndexFundDeposit.new(index_fund_deposit_params)  
    if @deposit.save
      redirect_to edit_index_fund_path(@deposit.index_fund_coin.index_fund)
    else
      flash.now[:alert] = @deposit.errors.full_messages.to_sentence
      render :new
    end
  end
  
  private
  
  def index_fund_deposit_params
    params.require(:index_fund_deposit).permit(:index_fund_coin_id, :qty, :base_coin_qty)
  end
  
end