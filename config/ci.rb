# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Test: RSpec", "bundle exec rspec"

  # No es un build de Docker (eso es Setup 18, todavía no hay Dockerfile) —
  # zeitwerk:check sí corre en el mismo entorno que el resto de la pipeline
  # y detecta autoload/constantes mal nombradas antes de llegar a producción.
  step "Build: Zeitwerk check", "bin/rails zeitwerk:check"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
