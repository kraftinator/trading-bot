class CreateIndexFundSnapshots < ActiveRecord::Migration[5.0]
  def change
    create_table :index_fund_snapshots do |t|
      t.integer :index_fund_id
      t.decimal :total_fund_qty, {:precision=>16, :scale=>8}
      t.decimal :total_deposit_qty, {:precision=>16, :scale=>8}
      t.timestamps
    end
  end
end
