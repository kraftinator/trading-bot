class CreateIndexFundOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :index_fund_orders do |t|
      t.integer :index_fund_coin_id
      t.string :side
      t.decimal :price, {:precision=>15, :scale=>8}
      t.decimal :qty, {:precision=>16, :scale=>8}, :default => 0
      t.string :order_uid
      t.timestamps
    end
  end
end
