class CreateSystemSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :system_settings do |t|
      t.string :active_theme, null: false, default: "light"
      t.string :brand_primary
      t.string :brand_secondary
      t.string :brand_accent

      t.timestamps
    end
  end
end
