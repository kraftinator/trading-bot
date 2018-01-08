class AddStateAndFilledAtToLimitOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :limit_orders, :state, :string
    add_column :limit_orders, :filled_at, :datetime
  end
end
