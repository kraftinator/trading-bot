class CreateStrategies < ActiveRecord::Migration[5.0]
  def change
    create_table :strategies do |t|
      t.string :name
    end
  end
end
