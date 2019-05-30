class CreateIndexFundDeposits < ActiveRecord::Migration[5.0]
  def change
    create_table :index_fund_deposits do |t|
      t.integer :index_fund_coin_id
      t.decimal :qty, {:precision=>16, :scale=>8}
      t.timestamps
    end
  end
end
