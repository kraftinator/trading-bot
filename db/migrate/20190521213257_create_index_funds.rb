class CreateIndexFunds < ActiveRecord::Migration[5.0]
  def change
    create_table :index_funds do |t|
      t.integer :user_id
      t.string :name
      t.integer :base_coin_id
      t.integer :rebalance_period, :default => 0
      t.decimal :rebalance_trigger_pct, {:precision=>5, :scale=>4}, :default => 0.02
      t.boolean :active, :default => false
      t.timestamps
    end
  end
end
