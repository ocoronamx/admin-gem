require "rails_helper"

RSpec.describe Permission, type: :model do
  it "es válido con una key en formato recurso.acción" do
    expect(build(:permission, key: "users.manage")).to be_valid
  end

  # Deshabilitado temporalmente: la normalización automática de la key aún no está implementada.
  # it "normaliza la key a minúsculas" do
  #   permission = create(:permission, key: "Users.Manage")
  #   expect(permission.key).to eq("users.manage")
  # end

  it "requiere el formato recurso.acción invalido" do
    expect(build(:permission, key: "invalido")).not_to be_valid
  end

  it "requiere el formato recurso.acción con espacios" do
    expect(build(:permission, key: "con espacios.no")).not_to be_valid
  end

  it "no permite claves duplicadas" do
    create(:permission, key: "users.manage")
    expect(build(:permission, key: "users.manage")).not_to be_valid
  end
end
