class ChangeVolumeDataTypeInTradingPairStats < ActiveRecord::Migration[5.0]
  def change
    change_column :trading_pair_stats, :volume, :integer
  end
end
