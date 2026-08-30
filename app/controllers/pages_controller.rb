class PagesController < ApplicationController
  before_action :ensure_local_environment, only: :styleguide

  skip_after_action :verify_pundit_authorization

  def styleguide
  end

  private

  def ensure_local_environment
    head :not_found unless Rails.env.local?
  end
end
