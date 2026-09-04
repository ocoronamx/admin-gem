class AddDeactivatedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    # nil = activo; con fecha = desactivado (ver docs/conventions/database.md ("Soft delete")
    add_column :users, :deactivated_at, :datetime
  end
end