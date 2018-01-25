class AddSellCountTriggerToTraders < ActiveRecord::Migration[5.0]
  def change
    add_column :traders, :sell_count_trigger, :integer, :default => 0
  end
end
