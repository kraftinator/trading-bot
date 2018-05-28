class AddLossPctToTraders < ActiveRecord::Migration[5.0]
  def change
    add_column :traders, :loss_pct, :decimal, :precision => 5, :scale => 4, :default => 0
  end
end
