class CreateTraders < ActiveRecord::Migration[5.0]
  def change
    create_table :traders do |t|
      t.integer :trading_pair_id
      t.decimal :coin_qty, {:precision=>16, :scale=>8}, :default => 0
      t.decimal :token_qty, {:precision=>16, :scale=>8}, :default => 0
      t.integer :strategy_id
      t.decimal :percentage_range, {:precision=>5, :scale=>4}, :default => 0.05
      t.integer :wait_period, :default => 0
      t.boolean :active, :default => false
      t.integer :buy_count, :default => 0
      t.integer :sell_count, :default => 0
      t.timestamps
    end
  end
end
