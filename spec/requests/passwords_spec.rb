require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "GET /passwords/new" do
    it "renderiza sin el AuthorizationNotPerformedError que tenía antes de este fix" do
      get new_password_path

      expect(response).to have_http_status(:ok)
    end
  end
end
