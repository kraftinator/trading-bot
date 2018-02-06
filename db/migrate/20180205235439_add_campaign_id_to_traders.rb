class AddCampaignIdToTraders < ActiveRecord::Migration[5.0]
  def change
    add_column :traders, :campaign_id, :integer
  end
end
