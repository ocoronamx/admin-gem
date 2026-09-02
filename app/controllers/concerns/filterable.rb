# Filtrado de tablas administrativas por lista blanca (ver ADR §8: nada de
# "filtrado mágico" tipo Ransack). `filterable_by` declara qué *scopes* puede
# invocar el controlador — nunca columnas crudas — así que cualquier otra
# clave en params[:q] se descarta acá, antes de tocar la base de datos.
module Filterable
  extend ActiveSupport::Concern

  included do
    class_attribute :filterable_scopes, default: []
  end

  class_methods do
    # Cada símbolo debe ser también el nombre de un scope en el modelo que
    # este controlador filtra (filterable_by :by_name requiere que el modelo
    # defina scope :by_name).
    def filterable_by(*scopes)
      self.filterable_scopes = scopes.map(&:to_sym)
    end
  end

  private

  def apply_filters(scope)
    filter_params.each { |name, value| scope = scope.public_send(name, value) if value.present? }
    scope
  end

  def filter_params
    params.fetch(:q, ActionController::Parameters.new).to_unsafe_h.symbolize_keys.slice(*filterable_scopes)
  end
end
