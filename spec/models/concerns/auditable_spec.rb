require "rails_helper"

RSpec.describe Auditable do
  let(:role) { create(:role) }

  it "registra un audit log al crear" do
    expect { create(:user, role: role) }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.action).to eq("create")
    expect(log.resource).to be_a(User)
  end

  it "registra el diff al actualizar, sin exponer password_digest" do
    user = create(:user, role: role)

    expect { user.update!(email_address: "nuevo@example.com") }.to change(AuditLog, :count).by(1)

    log = AuditLog.last
    expect(log.action).to eq("update")
    expect(log.changes_data).to have_key("email_address")
    expect(log.changes_data).not_to have_key("password_digest")
  end

  it "no registra nada si no hubo cambios reales" do
    user = create(:user, role: role)

    expect { user.save! }.not_to change(AuditLog, :count)
  end
end
