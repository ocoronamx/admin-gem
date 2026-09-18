class CreateSystemSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :system_settings do |t|
      t.string :app_name, null: false, default: "Admin Gem"
      t.string :support_email

      t.string :base_theme, null: false, default: "ink_bronze"
      t.string :color_mode, null: false, default: "light"

      # OKLCH — snapshot de los valores reales del tema base activo. Se
      # resincroniza sola al cambiar de base_theme (ver SystemSetting#sync_default_colors).
      t.jsonb :default_colors_light, null: false, default: {}
      t.jsonb :default_colors_dark,  null: false, default: {}

      # Hex — overrides de marca, independientes del tema base (un color
      # custom se mantiene igual sin importar qué paleta de fondo esté activa).
      t.jsonb :custom_colors_light, null: false, default: {}
      t.jsonb :custom_colors_dark,  null: false, default: {}

      # Respaldo de un nivel para "restaurar anteriores" — no reemplaza a
      # Auditable (ya incluido abajo), que guarda el historial completo.
      t.jsonb :previous_colors_light, null: false, default: {}
      t.jsonb :previous_colors_dark,  null: false, default: {}

      t.timestamps
    end
  end
end
