# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "turbo_confirm"
pin "tom-select" # @2.6.2 — UMD vendored a mano (unpkg), no el build modular de jspm
pin "charts/theme_colors"
pin "apexcharts" # @6.10.0
