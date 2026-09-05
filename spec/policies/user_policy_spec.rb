require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  describe UserPolicy do
    subject { described_class }

    let(:role) { create(:role, name: "Editor", key: "editor") }
    let(:user) { create(:user, role: role) }
    let(:other_user) { create(:user, role: role) }

    context "con permiso users.manage, prueba sobre otro usuario" do
      before { role.permissions << create(:permission, key: "users.manage") }

      it "permite desactivar a otro usuario" do
        expect(described_class.new(user, other_user)).to permit_action(:toggle_active?)
      end
    end

    context "con permiso users.manage, prueba sobre sí mismo" do
      before { role.permissions << create(:permission, key: "users.manage") }

      it "no permite desactivarse a sí mismo" do
        expect(described_class.new(user, user)).not_to permit_action(:toggle_active?)
      end
    end

    context "sin permiso users.manage" do
      it "no permite desactivar a nadie" do
        expect(described_class.new(user, other_user)).not_to permit_action(:toggle_active?)
      end
    end
  end
end
