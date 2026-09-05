require "rails_helper"

RSpec.describe "AuditLogs", type: :request do
  describe "GET /audit_logs" do
    it "redirige a iniciar sesión si no hay usuario autenticado" do
      get audit_logs_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
