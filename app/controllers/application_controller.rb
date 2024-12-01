class ApplicationController < ActionController::Base
  def init_breadcrumb(i18n)
    @breadcrumb = { title: I18n.t(:"#{i18n}"), list: [] }
    @breadcrumb[:list] << { href: demos_dashboard_path, text: I18n.t(:'demo.dashboard') }
  end
  def add_breadcrumb(path, i18n)
    @breadcrumb[:list] << { href: path, text: I18n.t(:"#{i18n}") }
  end

end
