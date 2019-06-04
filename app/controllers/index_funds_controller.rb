class IndexFundsController < ApplicationController
  
  before_action :set_index_fund, only: [:show, :edit, :update, :allocations, :toggle_active]
  before_action :load_index_fund_attributes, only: [:new, :edit]

  def index
    @index_funds = current_user.index_funds.all.to_a.sort_by(&:name)
  end
  
  def new
    @index_fund = IndexFund.new
  end
  
  def create
    @index_fund = IndexFund.new(index_fund_params)
    @index_fund.user = current_user
    if @index_fund.save
      #redirect_to allocations_index_fund_path(@index_fund)
      #ifc = IndexFundCoin.create(index_fund: @index_fund, allocation_pct: 0.1)
      @index_fund.index_fund_coins.create(allocation_pct: 0.1)
      redirect_to index_fund_path(@index_fund)
    else
      flash.now[:alert] = @index_fund.errors.full_messages.to_sentence
      load_index_fund_attributes
      render :new
    end
  end
  
  def allocations
    @ifc = IndexFundCoin.new(index_fund: @index_fund)
  end
  
  def toggle_active
    if @index_fund.active?
      @index_fund.update_column(:active, false)
    else
      @index_fund.update_column(:active, true)
    end
    redirect_to index_funds_path
  end
  
  def edit
  end
  
  def update
    if @index_fund.update(index_fund_params )
      redirect_to index_fund_path(@index_fund)
    else
      flash.now[:alert] = @index_fund.errors.full_messages.to_sentence
      load_index_fund_attributes
      render :edit
    end
  end

  def show
  end
  
  private
  
  def index_fund_params
    params.require(:index_fund).permit(:base_coin_id, :name, :rebalance_period, :rebalance_trigger_pct, :active)
  end
  
  def load_index_fund_attributes
    @base_coins = ExchangeCoin.base_coins.sort_by(&:full_display_name)
  end
  
  def set_index_fund
    @index_fund = IndexFund.find(params[:id])
  end
  
end
