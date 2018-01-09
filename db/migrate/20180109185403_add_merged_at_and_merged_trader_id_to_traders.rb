class AddMergedAtAndMergedTraderIdToTraders < ActiveRecord::Migration[5.0]
  def change
    add_column :traders, :merged_at, :datetime
    add_column :traders, :merged_trader_id, :integer
  end
end
