class CreateTradingPairs < ActiveRecord::Migration[5.0]
  def change
    create_table :trading_pairs do |t|
      t.integer :coin_id
      t.integer :token_id
      t.decimal :max_price, {:precision=>15, :scale=>8}
      t.timestamps
    end
  end
end
