require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "redirige a iniciar sesión si no hay usuario autenticado" do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
