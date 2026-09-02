require 'rails_helper'

RSpec.describe "Roles", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/roles/index"
      expect(response).to have_http_status(:success)
    end

    it "redirige a iniciar sesión si no hay usuario autenticado" do
      get roles_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
