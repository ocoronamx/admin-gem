require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  # let!(:role) { create(:role) }
  let!(:role) { create(:role, name: "Editor", key: "editor") }
  let!(:user) { create(:user, role: role) }
  let!(:other_user) { create(:user, role: role) }

  context "con permiso users.manage, sobre otro usuario" do
    before { role.permissions << create(:permission, key: "users.manage") }

    permissions :toggle_active? do
      it "permite desactivar a otro usuario" do
        expect(described_class).to permit(user, other_user)
      end
    end
  end

  context "con permiso users.manage, sobre sí mismo" do
    before { role.permissions << create(:permission, key: "users.manage") }

    permissions :toggle_active? do
      it "no permite desactivarse a sí mismo" do
        expect(described_class).not_to permit(user, user)
      end
    end
  end

  context "sin permiso users.manage" do
    permissions :toggle_active? do
      it "no permite desactivar a nadie" do
        expect(described_class).not_to permit(user, other_user)
      end
    end
  end
end
