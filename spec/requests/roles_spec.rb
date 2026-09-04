require 'rails_helper'

RSpec.describe "Roles", type: :request do
  describe "GET /index" do
    context "cuando el usuario está autenticado" do
      let(:role) do
        Role.create!(
          name: "Super Administrador",
          key: "super_admin"
        )
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
          password: "password123456"
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
  end
end
