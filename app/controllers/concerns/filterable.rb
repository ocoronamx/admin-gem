# Filtrado de tablas administrativas por lista blanca (ADR: nada de "filtrado
# mágico" tipo Ransack). `filterable_by` mapea la clave pública de params[:q]
# al scope que la resuelve — nunca al revés. Cualquier clave que no esté en
# ese mapa se descarta acá, antes de tocar la base de datos.
module Filterable
  extend ActiveSupport::Concern

  included do
    class_attribute :filterable_scopes, default: {}
  end

  class_methods do
    # filterable_by(name: :by_name, key: :by_key) acepta ?q[name]=... y
    # llama Role.by_name(...) — la clave pública no tiene que llamarse igual
    # que el scope.
    def filterable_by(mapping)
      self.filterable_scopes = mapping.symbolize_keys
    end
  end

  private

  def apply_filters(scope)
    filter_params.each do |key, value|
      scope_method = filterable_scopes[key]
      scope = scope.public_send(scope_method, value) if scope_method && value.present?
    end
    scope
  end

  def filter_params
    params.fetch(:q, ActionController::Parameters.new).to_unsafe_h.symbolize_keys.slice(*filterable_scopes.keys)
  end
end
