# Form builder por defecto de toda la app (ver config/application.rb).
#
# Envuelve cada campo en el markup de DaisyUI v5 (fieldset + label + el input
# real + validator-hint) para que ningún módulo futuro (Setup 13 en adelante)
# tenga que repetir esa estructura a mano, como pasaba en sessions/passwords
# antes de esta fase.
#
# Usa las clases nativas de validación de DaisyUI v5 (`validator` +
# `validator-hint`, ver docs/conventions/forms.md) apoyadas en atributos
# HTML5 nativos (required, minlength, type="email"...) — sin JS. Los errores
# de servidor (object.errors) se muestran con ese mismo `validator-hint`.
class AdminFormBuilder < ActionView::Helpers::FormBuilder
  # Usado por `tom_select` para llamar al `select` original sin pasar por el
  # override de abajo (evitaría envolver el fieldset dos veces). Es un método
  # real en ActionView::Helpers::FormBuilder, no method_missing — bind_call
  # es seguro.
  NATIVE_SELECT = ActionView::Helpers::FormBuilder.instance_method(:select)
  private_constant :NATIVE_SELECT

  def text_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  def email_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  def password_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  def number_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  # Input nativo de fecha — sin JS (ver ADR §3.4, Flatpickr descartado por
  # abandono). Si algún día hace falta time_field/datetime_local_field, el
  # patrón es idéntico: cópialo.
  def date_field(attribute, options = {})
    field(attribute, options) { |opts| super(attribute, opts) }
  end

  def text_area(attribute, options = {})
    field(attribute, options, css_class: "textarea") { |opts| super(attribute, opts) }
  end

  def check_box(attribute, options = {}, checked_value = "1", unchecked_value = "0")
    label_text = options.delete(:label) { default_label(attribute) }
    hint_text  = options.delete(:hint)

    opts = options.dup
    opts[:class] = [ "checkbox", options[:class] ].compact.join(" ")

    @template.content_tag(:fieldset, class: "fieldset w-full") do
      @template.safe_join([
        @template.content_tag(:label, class: "label cursor-pointer justify-start gap-3") do
          @template.safe_join([ super(attribute, opts, checked_value, unchecked_value), label_text ])
        end,
        (hint(attribute, hint_text, error: false) if hint_text.present?)
      ].compact)
    end
  end

  # <select> nativo de Rails, estilizado. `label:`/`hint:` se aceptan en
  # options (3er argumento) o en html_options (4to) — el que te resulte
  # más natural en cada llamada.
  def select(attribute, choices, options = {}, html_options = {}, &block)
    passthrough = options.slice(:label, :hint)
    select_opts = options.except(:label, :hint)
    merged_html = html_options.reverse_merge(passthrough)

    field(attribute, merged_html, css_class: "select") do |opts|
      super(attribute, choices, select_opts, opts, &block)
    end
  end

  # <select> potenciado con Tom Select (búsqueda, tags, multi-selección).
  # `tom_select_options` viaja tal cual al constructor de TomSelect en JS
  # (ver app/javascript/controllers/tom_select_controller.js). Si el JS no
  # carga, esto sigue siendo un <select multiple> normal — no queda invisible.
  def tom_select(attribute, choices, options = {}, tom_select_options = {})
    select_opts = options.slice(:include_blank, :prompt, :selected, :disabled)

    field(attribute, options, css_class: "select") do |opts|
      opts[:data] = (opts[:data] || {}).merge(
        controller: "tom-select",
        "tom-select-options-value": tom_select_options.to_json
      )
      NATIVE_SELECT.bind_call(self, attribute, choices, select_opts, opts)
    end
  end

  private

  # Envuelve cualquier campo en fieldset + label + el input real + hint/error.
  # `css_class` es la clase base de DaisyUI para ese campo ("input" para casi
  # todos; "textarea"/"select" para los que la necesitan distinta).
  def field(attribute, options, css_class: "input")
    options    = options.dup
    label_text = options.delete(:label) { default_label(attribute) }
    hint_text  = options.delete(:hint)
    errors     = object.respond_to?(:errors) ? Array(object.errors[attribute]) : []
    message    = errors.first || hint_text

    opts = options.dup
    opts[:class] = [ css_class, "validator", options[:class] ].compact.join(" ")
    opts[:"aria-describedby"] = field_id(attribute, :hint) if message.present?

    @template.content_tag(:fieldset, class: "fieldset w-full") do
      @template.safe_join([
        label(attribute, label_text, class: "label"),
        yield(opts),
        hint(attribute, message, error: errors.any?)
      ].compact)
    end
  end

  def hint(attribute, message, error:)
    return if message.blank?

    css = error ? "validator-hint" : "label -mt-1 text-xs text-base-content/60"
    @template.content_tag(:p, message, id: field_id(attribute, :hint), class: css)
  end

  # object puede ser nil (form_with sin `model:`, como sessions/passwords) —
  # NilClass no tiene human_attribute_name, así que caemos a humanize.
  def default_label(attribute)
    klass = object.class
    klass.respond_to?(:human_attribute_name) ? klass.human_attribute_name(attribute) : attribute.to_s.humanize
  end
end
