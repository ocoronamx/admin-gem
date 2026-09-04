module ChartsHelper
  # Contenedor para un chart de ApexCharts. El JS (chart_controller.js) lee
  # type/series/options desde los data-* y arma la configuración completa —
  # acá no se decide ningún color, eso sale del tema activo en tiempo real.
  #
  #   chart_tag type: :line, series: [{ name: "Ventas", data: [1, 2, 3] }],
  #     xaxis: { categories: %w[Ene Feb Mar] }
  #
  # `options` viaja tal cual a ApexCharts — cualquier clave que la librería
  # acepte funciona sin tener que agregar nada acá.
  def chart_tag(type:, series:, id: nil, height: 320, **options)
    content_tag :div, "",
      id: id,
      style: "min-height: #{height}px",
      data: {
        controller: "chart",
        chart_type_value: type.to_s,
        chart_series_value: series,
        chart_options_value: options
      }
  end
end
