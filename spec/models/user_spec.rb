require "rails_helper"

RSpec.describe User, type: :model do
  it "normaliza el email a minúsculas y sin espacios" do
    user = build(:user, email_address: "  Persona@Ejemplo.com ")
    expect(user.email_address).to eq("persona@ejemplo.com")
  end

  it "es válido con una contraseña de 12 caracteres o más" do
    expect(build(:user, password: "contraseña-larga-123")).to be_valid
  end

  it "es inválido con una contraseña más corta de 12 caracteres" do
    expect(build(:user, password: "corta")).not_to be_valid
  end

  it "delega permits? al rol asignado" do
    # create(:role, name: "Administrador", key: 'admin',  permissions: %w[users.view users.manage])
    role = create(:role, name: "Administrador", key: 'admin')
    role.permissions << create(:permission, key: "users.view")
    user = create(:user, email_address: 'user@mail.com', password: 'admin gem strong password', role: role)

    expect(user.permits?("users.view")).to be true
  end

  it "No delega permits? al rol asignado" do
    # create(:role, name: "Administrador", key: 'admin',  permissions: %w[users.view users.manage])
    role = create(:role, name: "Administrador", key: 'admin')
    role.permissions << create(:permission, key: "users.view")
    user = create(:user, email_address: 'user@mail.com', password: 'admin gem strong password', role: role)

    expect(user.permits?("users.manage")).to be false
  end
end
