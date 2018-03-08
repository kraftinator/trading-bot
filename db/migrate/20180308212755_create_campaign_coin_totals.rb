class CreateCampaignCoinTotals < ActiveRecord::Migration[5.0]
  def change
    create_table :campaign_coin_totals do |t|
      t.integer :campaign_id
      t.decimal :coin1_total, {:precision=>16, :scale=>8}, :default => 0
      t.decimal :coin2_total, {:precision=>16, :scale=>8}, :default => 0
      t.decimal :initial_coin2_total, {:precision=>16, :scale=>8}, :default => 0
      t.decimal :projected_coin2_total, {:precision=>16, :scale=>8}, :default => 0
      t.timestamps
    end
  end
end
