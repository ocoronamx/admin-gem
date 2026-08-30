# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Sin registro público en este boilerplate: las cuentas las crea un admin
# (Setup 13) o, para el arranque inicial, se siembra aquí vía variables de entorno.
if User.none?
  email = ENV["SEED_ADMIN_EMAIL"]
  password = ENV["SEED_ADMIN_PASSWORD"]

  if email.present? && password.present?
    User.create!(email_address: email, password: password)
    puts "Usuario administrador creado: #{email}"
  else
    puts "Sin usuarios y sin SEED_ADMIN_EMAIL/SEED_ADMIN_PASSWORD — no se creó ningún usuario."
  end
end
