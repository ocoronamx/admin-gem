class SystemSettingsController < ApplicationController
  before_action :set_system_setting

  def edit
    authorize @system_setting
  end

  def update
    authorize @system_setting

    if @system_setting.update(system_setting_params)
      redirect_to edit_system_setting_path, notice: "Configuración actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_system_setting
    @system_setting = SystemSetting.instance
  end

  def system_setting_params
    params.require(:system_setting).permit(:active_theme, :brand_primary, :brand_secondary, :brand_accent)
  end
end
