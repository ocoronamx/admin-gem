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
    # unsafe-inline acá, no en script-src: ApexCharts y Turbo fijan estilos
    # vía elemento.style / <style> dinámico en tiempo real — un nonce NUNCA
    # puede cubrir eso (solo cubre <style> estático con el atributo nonce=
    # puesto a mano). No ejecuta JS, así que el riesgo real de XSS (que sigue
    # cubierto por script-src estricto) no se ve afectado.
    policy.style_src       :self, :unsafe_inline
    policy.connect_src     :self
    policy.base_uri        :none
    policy.frame_ancestors :none
  end

  # El importmap de Rails inyecta <script type="importmap"> y el bootstrap
  # de módulos como scripts inline — sin nonce, script-src :self los
  # bloquearía y se cae toda la app.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }

  # Solo scripts usan nonce. style-src usa unsafe-inline (ver arriba) —
  # mezclar nonce + unsafe-inline en el mismo directive hace que el navegador
  # IGNORE unsafe-inline (así lo define el spec), así que style-src no va acá.
  config.content_security_policy_nonce_directives = %w[script-src]
end
