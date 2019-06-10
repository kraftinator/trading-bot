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
=begin
  def show
    @fund_total = @index_fund.fund_total
    
    @assets = @index_fund.index_fund_coins
    @assets.each do |asset|
      if asset.base_coin?
        asset.price = 1.0
        asset.base_coin_value = asset.qty
      else
        asset.price = @index_fund.exchange.cached_fiat_stats(asset.coin).last_price
        asset.base_coin_value = asset.qty*asset.price
      end
    end
    
    total_base_coin_value = 0
    @assets.each { |asset| total_base_coin_value+=asset.base_coin_value }

    @assets.each { |asset| asset.current_allocation_pct = asset.base_coin_value/total_base_coin_value}
    
    
    @assets = @assets.sort_by(&:base_coin_value).reverse
    
  end
  
  
  def show
    @assets, @fund_total = @index_fund.calculate_fund_stats
    @assets.each { |asset| asset.current_allocation_pct = asset.base_coin_value/@fund_total}
    @assets = @assets.sort_by(&:base_coin_value).reverse
    @deposit_total = @index_fund.deposit_total

    @deposits = []
    @assets.each { |asset| @deposits.concat(asset.index_fund_deposits) }
    @deposits = @deposits.sort_by(&:created_at).reverse
    

  end
=end  
  
  def show
    @assets, @fund_total = @index_fund.calculate_fund_stats
    #@assets.each { |asset| asset.current_allocation_pct = asset.base_coin_value/@fund_total}
    @assets.each { |asset| asset.current_allocation_pct = @fund_total == 0 ? 0 : asset.base_coin_value/@fund_total }    
    @assets = @assets.sort_by(&:base_coin_value).reverse
    @deposit_total = @index_fund.deposit_total
    @deposits = @index_fund.deposits
    @orders = @index_fund.orders
    
    profit = @fund_total-@deposit_total
    @profit_change = {}
    # 1 hour
    snapshot = @index_fund.snapshot_by_date(1.hour.ago)
    #@profit_change['1h'] = profit/snapshot.profit-1 if snapshot
    @profit_change['1h'] = @fund_total/snapshot.total_fund_qty-1 if snapshot
    # 24 hours
    snapshot = @index_fund.snapshot_by_date(1.day.ago)
    #@profit_change['24h'] = profit/snapshot.profit-1 if snapshot
    @profit_change['24h'] = @fund_total/snapshot.total_fund_qty-1 if snapshot
    # 1 week
    snapshot = @index_fund.snapshot_by_date(1.week.ago)
    #@profit_change['1w'] = profit/snapshot.profit-1 if snapshot
    @profit_change['1w'] = @fund_total/snapshot.total_fund_qty-1 if snapshot
    # 1 month
    snapshot = @index_fund.snapshot_by_date(30.days.ago)
    #@profit_change['1m'] = profit/snapshot.profit-1 if snapshot
    @profit_change['1m'] = @fund_total/snapshot.total_fund_qty-1 if snapshot
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
