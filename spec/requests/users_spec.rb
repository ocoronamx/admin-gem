require "rails_helper"

RSpec.describe "Users", type: :request do
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: user.password }
  end

  let(:manage_role) { create(:role, name: "Admin", key: "admin_test") }
  let(:admin) { create(:user, role: manage_role, password: "contraseña-larga-123") }

  before { manage_role.permissions << create(:permission, key: "users.manage") }

  describe "GET /users" do
    it "redirige a iniciar sesión si no hay usuario autenticado" do
      get users_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "PATCH /users/:id/toggle_active" do
    it "desactiva a otro usuario y corta su sesión" do
      sign_in(admin)
      target = create(:user, role: manage_role, password: "contraseña-larga-123")

      patch toggle_active_user_path(target)
      target.reload

      expect(target.active?).to be false
      expect(target.sessions.count).to eq(0)
    end

    it "impide desactivarse a sí mismo" do
      sign_in(admin)

      patch toggle_active_user_path(admin)

      expect(response).to redirect_to(root_path)
      expect(admin.reload.active?).to be true
    end
  end

  describe "un usuario desactivado" do
    it "no puede iniciar sesión" do
      inactive = create(:user, role: manage_role, password: "contraseña-larga-123", deactivated_at: Time.current)

      sign_in(inactive)

      expect(response).to redirect_to(new_session_path)
    end
  end
end