class CreatePartiallyFilledOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :partially_filled_orders do |t|
      t.integer :limit_order_id
      t.decimal :executed_qty, {:precision=>16, :scale=>8}
      t.timestamps
    end
  end
end
