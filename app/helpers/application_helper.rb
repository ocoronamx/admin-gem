# Helper general para la interfaz y utilidades de presentación globales.
module ApplicationHelper
  # Mapea un tipo de mensaje flash de Rails a su clase de variante correspondiente en DaisyUI.
  #
  # @param type [String, Symbol] El tipo de mensaje flash (ej. :notice, :alert, "success").
  # @return [String] La clase de alerta de DaisyUI correspondiente (ej. "alert-success").
  #   Si el tipo no coincide con ninguna clave, retorna "alert-info" por defecto.
  #
  # @example
  #   flash_alert_class(:success)  #=> "alert-success"
  #   flash_alert_class("notice")  #=> "alert-info"
  #   flash_alert_class(:unknown) #=> "alert-info"
  def flash_alert_class(type)
    {
      "notice" => "alert-info",
      "success" => "alert-success",
      "alert" => "alert-error",
      "error" => "alert-error",
      "warning" => "alert-warning"
    }.fetch(type.to_s, "alert-info")
  end
end
