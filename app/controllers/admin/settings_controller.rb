class Admin::SettingsController < Admin::BaseController
  before_action :authorise_admin_settings

  def show
    @settings = Settings.instance
  end

  def audits
    @audits = SettingsAudit
                .includes(:user)
                .order(created_at: :desc)
                .page(params[:page] || 1)
                .per(25)
  end
end
