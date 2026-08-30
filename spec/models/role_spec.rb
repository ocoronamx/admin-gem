require "rails_helper"

RSpec.describe Role, type: :model do
  it "requiere un nombre único" do
    create(:role, name: "Administrador", key: 'admin')
    expect(build(:role, name: "Administrador", key: 'admin')).not_to be_valid
  end

  it "expone si tiene una key de permiso concreta" do
    role = create(:role, name: "Super", key: 'super')
    role.permissions << create(:permission, key: "users.manage")

    expect(role.permits?("users.manage")).to be true
  end

  it "expone si no tiene una key de permiso concreta" do
    role = create(:role, name: "Super", key: 'super')
    role.permissions << create(:permission, key: "users.manage")

    expect(role.permits?("users.view")).to be false
  end
end
