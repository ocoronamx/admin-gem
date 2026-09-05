class ChangeRoleIdNullConstraintOnUsers < ActiveRecord::Migration[8.1]
  # Clases locales a la migración, no los modelos de la app — mismo patrón
  # que AddRoleToUsers (Setup 7): si Role/User cambian de forma en el
  # futuro, esta migración histórica sigue funcionando igual.
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationRole < ActiveRecord::Base
    self.table_name = "roles"
  end

  def up
    # Defensivo: si algún usuario quedó sin rol (no debería, pero por si
    # acaso en dev/test), se le asigna "admin" antes de bloquear el NULL.
    default_role = MigrationRole.find_by(key: "admin") || MigrationRole.first
    MigrationUser.where(role_id: nil).update_all(role_id: default_role.id) if default_role

    change_column_null :users, :role_id, false
  end

  def down
    change_column_null :users, :role_id, true
  end
end
