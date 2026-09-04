require "rails_helper"

RSpec.describe "Roles", type: :request do
  describe "GET /index" do
    context "cuando el usuario está autenticado" do
      let(:role) do
        Role.create!(name: "Super Administrador", key: "super_admin").tap do |role|
          role.permissions << Permission.create!(key: "roles.view")
        end
      end

      let(:user) do
        User.create!(
          email_address: "admin@example.com",
          password: "password123456",
          role: role
        )
      end

      before do
        post session_path, params: {
          email_address: user.email_address,
          password: user.password
        }
      end

      it "returns http success" do
        get roles_path
        expect(response).to have_http_status(:success)
      end
    end

    context "cuando no hay usuario autenticado" do
      it "redirige a iniciar sesión" do
        get roles_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    it "rechaza a un usuario autenticado sin permiso roles.view" do
      user = create(:user, email_address: "foo@example.com", password: "password123456",
                    role: create(:role, name: "Sin permisos", key: "sin_permisos"))
      post session_path, params: { email_address: user.email_address, password: user.password }

      get roles_path

      expect(response).to redirect_to(root_path)
    end
  end
end
