require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /session/new" do
    it "renderiza el login con el markup de AdminFormBuilder" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end

    it "Comprueba elemento fieldset" do
      get new_session_path

      expect(response.body).to include("<fieldset")
    end

    it "Comprueba elemento validator" do
      get new_session_path

      expect(response.body).to include("input validator")
    end

    it "Comprueba elemento Correo" do
      get new_session_path

      expect(response.body).to include("Correo")
    end
  end
end
