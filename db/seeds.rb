# Sin registro público en este boilerplate: las cuentas las crea un admin
# (Setup 13) o, para el arranque inicial, se siembra aquí vía variables de entorno.
#
# Cada módulo nuevo declara sus propios permisos "<recurso>.view" / "<recurso>.manage"
# (ver docs/conventions/authorization.md). Por ahora solo existe "users".
permission_keys = %w[users.view users.manage roles.view roles.manage]
permissions_by_key = permission_keys.index_with { |key| Permission.find_or_create_by!(key: key) }

roles = {
  "super"    => { name: "Super",         permissions: permission_keys },
  "admin"    => { name: "Administrator", permissions: permission_keys },
  "standard" => { name: "Standard",      permissions: %w[users.view] },
  "client"   => { name: "Client",        permissions: [] },
  "guest"    => { name: "Guest",         permissions: [] }
}

roles.each do |key, attrs|
  role = Role.find_or_initialize_by(key: key)
  role.name = attrs[:name]
  role.save!

  # Asignar la asociación has_many :through crea/borra los RolePermission
  # necesarios automáticamente — no hay que tocar esa tabla a mano.
  role.permissions = attrs[:permissions].map { |k| permissions_by_key.fetch(k) }

  puts "Rol listo: #{role.name} (#{role.permissions.count} permisos)"
end

if User.none?
  email = ENV["SEED_ADMIN_EMAIL"]
  password = ENV["SEED_ADMIN_PASSWORD"]

  if email.present? && password.present?
    super_role = Role.find_by!(key: "super")
    User.create!(email_address: email, password: password, role: super_role)
    puts "Usuario administrador creado: #{email}, rol: #{super_role&.name}"
  else
    puts "Sin usuarios y sin SEED_ADMIN_EMAIL/SEED_ADMIN_PASSWORD — no se creó usuario administrador."
  end

  guest_role = Role.find_by!(key: "guest")
  User.create!(email_address: 'guest@example.com', password: 'password123456', role: guest_role)
end
