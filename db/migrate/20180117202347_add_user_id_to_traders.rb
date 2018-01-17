class AddUserIdToTraders < ActiveRecord::Migration[5.0]
  def change
    add_column :traders, :user_id, :integer
  end
end
