class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :key, null: false

      t.timestamps
    end
    add_index :roles, :name, unique: true
    add_index :roles, :key, unique: true
    add_reference :users, :role, foreign_key: true
  end
end
