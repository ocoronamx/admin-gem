# Be sure to restart your server when you modify this file.

# Nada se carga desde un CDN externo en este proyecto — Turbo/Stimulus, Tom
# Select y ApexCharts están vendorizados vía importmap (Setup 9/11), y
# Tailwind se compila localmente (Setup 4). Eso permite una política
# estricta, sin tener que listar dominios de terceros.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.font_src        :self
    policy.img_src         :self, :data
    policy.object_src      :none
    policy.script_src      :self
    policy.style_src       :self
    policy.connect_src     :self
    policy.base_uri        :none
    policy.frame_ancestors :none
  end

  # El importmap de Rails inyecta <script type="importmap"> y el bootstrap
  # de módulos como scripts inline — sin nonce, script-src :self los
  # bloquearía y se cae toda la app. No hace falta nonce en style-src: el
  # único style="" inline que había (charts_helper.rb) se movió a JS en esta
  # misma fase — ver app/javascript/controllers/chart_controller.js.

  # Generar un nonce (token de un solo uso) de forma dinámica
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }

  # Aplica el nonce a scripts y estilos.
  # Esto permite que Rails/Turbo inyecten estilos dinámicos de forma segura sin requerir 'unsafe-inline'.
  config.content_security_policy_nonce_directives = %w[script-src]
end
