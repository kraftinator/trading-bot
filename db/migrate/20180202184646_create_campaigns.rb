class CreateCampaigns < ActiveRecord::Migration[5.0]
  def change
    create_table :campaigns do |t|
      t.integer :user_id
      t.integer :exchange_trading_pair_id
      t.decimal :max_price, {:precision=>15, :scale=>8}
      t.timestamps
    end
  end
end
