class AddStateAndOpenToIndexFundOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :index_fund_orders, :state, :string
    add_column :index_fund_orders, :open, :boolean
    add_column :index_fund_orders, :filled_at, :datetime
  end
end
