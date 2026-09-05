require "rails_helper"

RSpec.describe Auditable do
  # let!(:role) { create(:role, name: "Prueba", key: "prueba") }
before { manage_role.permissions << create(:permission, key: "users.manage") }
  context "cuando se crea un recurso" do
    it "incrementa la cantidad de registros en AuditLog" do
      expect { create(:user, role: role) }.to change(AuditLog, :count).by(1)
    end
  end

  describe "atributos del log al crear" do
    let(:log) { AuditLog.last }

    before { create(:user, role: role) }

    it "registra la acción como create" do
      expect(log.action).to eq("create")
    end

    it "asigna el recurso correspondiente" do
      expect(log.resource).to be_a(User)
    end
  end

  context "cuando se actualiza un recurso con cambios" do
    let!(:user) { create(:user, role: role) }

    it "incrementa la cantidad de registros en AuditLog" do
      expect { user.update!(email_address: "nuevo@example.com") }.to change(AuditLog, :count).by(1)
    end
  end

  describe "atributos del log al actualizar" do
    let!(:user) { create(:user, role: role) }
    let(:log) { AuditLog.last }

    before { user.update!(email_address: "nuevo@example.com") }

    it "registra la acción como update" do
      expect(log.action).to eq("update")
    end

    it "no expone password_digest en los datos" do
      expect(log.changes_data).not_to have_key("password_digest")
    end

    it "registra el campo modificado" do
      expect(log.changes_data).to have_key("email_address")
    end
  end

  context "cuando se actualiza un recurso sin cambios" do
    let!(:user) { create(:user, role: role) }

    it "no registra un nuevo log" do
      expect { user.save! }.not_to change(AuditLog, :count)
    end
  end
end
