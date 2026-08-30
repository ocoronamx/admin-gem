class PagesController < ApplicationController
  skip_after_action :verify_authorized, raise: false
  before_action :ensure_local_environment, only: :styleguide

  def styleguide
  end

  private

  def ensure_local_environment
    head :not_found unless Rails.env.local?
  end
end
