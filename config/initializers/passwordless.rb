Passwordless.configure do |config|
  config.default_from_address = "something@www.gov.uk"
  config.parent_controller = "ActionController::Base"
  config.parent_mailer = "ApplicationMailer"
  config.redirect_back_after_sign_in = true
end

Rails.application.config.to_prepare do
  Passwordless::Session.strict_loading_by_default = false
end
