require "rails_helper"

RSpec.describe AuditLogsHelper, type: :helper do
  describe "#format_audit_changes" do
    it "formatea cada atributo cambiado como 'atributo: viejo → nuevo'" do
      changes = { "email_address" => [ "a@x.com", "b@x.com" ] }
      expect(helper.format_audit_changes(changes)).to eq("email_address: a@x.com → b@x.com")
    end

    it "devuelve un placeholder cuando no hay cambios" do
      expect(helper.format_audit_changes({})).to eq("—")
    end
  end

  describe "#audit_action_badge" do
    it "usa badge-success para create" do
      expect(helper.audit_action_badge("create")).to include("badge-success")
    end

    it "usa badge-error para destroy" do
      expect(helper.audit_action_badge("destroy")).to include("badge-error")
    end

    it "usa un badge neutro para una acción desconocida" do
      expect(helper.audit_action_badge("algo_raro")).to include("badge-ghost")
    end
  end
end
