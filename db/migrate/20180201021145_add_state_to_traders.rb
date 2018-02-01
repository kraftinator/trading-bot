class AddStateToTraders < ActiveRecord::Migration[5.0]
  def change
    add_column :traders, :state, :string
  end
end
