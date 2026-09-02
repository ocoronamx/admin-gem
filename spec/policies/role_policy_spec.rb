require "rails_helper"

RSpec.describe RolePolicy, type: :policy do
  describe RolePolicy do
    subject { described_class }

    let(:role) { create(:role, name: "Editor", key: "editor") }
    let(:user) { create(:user, role: role) }
    let(:record) { Role }

    context "con permiso roles.view" do
      before { role.permissions << create(:permission, key: "roles.view") }

      permissions :index?, :show? do
        it { is_expected.to permit(user, record) }
      end

      permissions :create?, :update?, :destroy? do
        it { is_expected.not_to permit(user, record) }
      end
    end

    context "sin ningún permiso" do
      permissions :index?, :create? do
        it { is_expected.not_to permit(user, record) }
      end
    end

    describe "Scope" do
      it "resuelve el scope completo con permiso de vista" do
        role.permissions << create(:permission, key: "roles.view")
        expect(described_class::Scope.new(user, Role.all).resolve).to include(role)
      end

      it "resuelve un scope vacío sin permiso" do
        sin_permiso = create(:user, role: create(:role, name: "Sin permisos", key: "sin_permisos"))
        expect(described_class::Scope.new(sin_permiso, Role.all).resolve).to be_empty
      end
    end
  end
end
