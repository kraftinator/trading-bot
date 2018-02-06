class AddNameToCoins < ActiveRecord::Migration[5.0]
  def change
    add_column :coins, :name, :string
  end
end
