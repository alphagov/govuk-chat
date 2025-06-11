class Api::BaseController < ApplicationController
  before_action :check_api_access
  skip_before_action :verify_authenticity_token

private

  def check_api_access
    return if settings.api_access_enabled

    render(
      json: GenericErrorBlueprint.render(message: "Service unavailable"),
      status: :service_unavailable,
    )
  end

  def settings
    Settings.instance
  end
end
