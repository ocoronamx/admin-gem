class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true # nil = acción sin actor (seeds, jobs)
      t.references :resource, polymorphic: true, null: false
      t.string :action, null: false
      t.jsonb :changes_data, null: false, default: {}
      t.string :ip_address
      t.string :user_agent

      t.datetime :created_at, null: false
      # Sin updated_at: un audit log es inmutable — se crea, nunca se edita.
    end

    add_index :audit_logs, :action
  end
end
