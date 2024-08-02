class Admin::SettingsController < Admin::BaseController
  def show
    @settings = Settings.instance
  end
end
