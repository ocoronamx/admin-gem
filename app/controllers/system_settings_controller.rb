class SystemSettingsController < ApplicationController
  before_action :set_system_setting

  def edit
    authorize @system_setting
  end

  def update
    authorize @system_setting

    @system_setting.assign_attributes(system_setting_params.except(*color_keys, :remove_logo, :remove_favicon))
    @system_setting.assign_custom_colors(@system_setting.color_mode, color_params) if color_params.any?
    @system_setting.logo.purge if params.dig(:system_setting, :remove_logo) == "1"
    @system_setting.favicon.purge if params.dig(:system_setting, :remove_favicon) == "1"

    if @system_setting.save
      redirect_to edit_system_setting_path, notice: "Configuración actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_color_mode
    authorize @system_setting, :update?
    @system_setting.update!(color_mode: @system_setting.color_mode == "light" ? "dark" : "light")
    redirect_back fallback_location: root_path
  end

  def restore_previous_colors
    authorize @system_setting, :update?
    @system_setting.restore_previous_colors!(@system_setting.color_mode)
    redirect_to edit_system_setting_path, notice: "Colores anteriores restaurados."
  end

  def reset_colors
    authorize @system_setting, :update?
    @system_setting.reset_colors_to_theme_default!(@system_setting.color_mode)
    redirect_to edit_system_setting_path, notice: "Colores del tema restaurados."
  end

  private

  def color_keys = %i[primary secondary accent]

  def set_system_setting
    @system_setting = SystemSetting.instance
  end

  def system_setting_params
    params.require(:system_setting).permit(:app_name, :support_email, :base_theme, :color_mode, :logo, :favicon, *color_keys)
  end

  def color_params
    system_setting_params.slice(*color_keys).to_h.stringify_keys.compact_blank
  end
end
