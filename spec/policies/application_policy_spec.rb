require "rails_helper"

class Widget; end

class WidgetPolicy < ApplicationPolicy
  def show?
    user.role.permissions.exists?(key: "widgets.view")
  end

  def index?
    show?
  end

  def create?
    user.role.permissions.exists?(key: "widgets.manage")
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.role.permissions.exists?(key: "widgets.view")
        scope.all
      else
        scope.none
      end
    end
  end
end

# 1. El describe principal ahora coincide con el nombre del archivo (application_policy_spec.rb)
# 2. Anidamos WidgetPolicy adentro. RuboCop será feliz y `described_class` apuntará a WidgetPolicy.
RSpec.describe ApplicationPolicy, type: :policy do
  describe WidgetPolicy do
    subject { described_class }

    let(:role) { create(:role, name: "Administrador", key: "admin") }
    let(:user) { create(:user, email_address: "user@mail.com", password: "password 1 2 3", role: role) }

    let(:record) { instance_double(Widget) }

    context "with permiso widgets.view" do
      before { role.permissions << create(:permission, key: "widgets.view") }

      permissions :show?, :index? do
        it { is_expected.to permit(user, record) }
      end

      permissions :create?, :update?, :destroy? do
        it { is_expected.not_to permit(user, record) }
      end
    end

    context "with permiso widgets.manage" do
      before { role.permissions << create(:permission, key: "widgets.manage") }

      permissions :create?, :update?, :destroy? do
        it { is_expected.to permit(user, record) }
      end
    end

    context "without ningún permiso" do
      permissions :show?, :create? do
        it { is_expected.not_to permit(user, record) }
      end
    end

    describe "Scope" do
      it "resuelve todo el scope con permiso de vista" do
        role = create(:role, key: "viewer")
        role.permissions << create(:permission, key: "widgets.view")
        user = create(:user, role: role)

        expect(described_class::Scope.new(user, Permission.all).resolve).to eq(Permission.all)
      end

      it "resuelve un scope vacío sin permiso" do
        user = create(:user, role: create(:role, key: "viewer_sin_permiso"))

        expect(described_class::Scope.new(user, Permission.all).resolve).to be_empty
      end
    end
  end
end
