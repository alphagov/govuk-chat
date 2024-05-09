class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods
  before_action { authenticate_user! unless Rails.configuration.available_without_signon_authentication }
  before_action :set_current

  if ENV["BASIC_AUTH_USERNAME"]
    http_basic_authenticate_with(
      name: ENV.fetch("BASIC_AUTH_USERNAME"),
      password: ENV.fetch("BASIC_AUTH_PASSWORD"),
    )
  end

private

  def set_current
    Current.user = current_user
  end
end
