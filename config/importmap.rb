# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "turbo_confirm"
pin "tom-select"
pin "apexcharts" # @7.1.0
pin "apexcharts/core", to: "apexcharts--core.js" # @7.1.0
pin "charts/theme_colors"