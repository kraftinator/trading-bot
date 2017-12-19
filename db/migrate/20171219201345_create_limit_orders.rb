class CreateLimitOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :limit_orders do |t|
      t.integer :trader_id
      t.integer :order_guid
      t.decimal :price, {:precision=>15, :scale=>8}
      t.decimal :qty, {:precision=>16, :scale=>8}
      t.string :side
      t.boolean :open
      t.timestamps
    end
  end
end
