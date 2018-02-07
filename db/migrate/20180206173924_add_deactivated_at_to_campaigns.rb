class AddDeactivatedAtToCampaigns < ActiveRecord::Migration[5.0]
  def change
    add_column :campaigns, :deactivated_at, :datetime
  end
end
