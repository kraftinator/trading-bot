class AddOrderUidToLimitOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :limit_orders, :order_uid, :string
  end
end
