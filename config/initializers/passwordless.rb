Passwordless.configure do |config|
  config.default_from_address = "something@www.gov.uk"
  config.parent_controller = "ActionController::Base"
  config.parent_mailer = "ApplicationMailer"
  config.redirect_back_after_sign_in = true
  # config.after_session_save = lambda do |session, _request|
  #   SigninMailer.sign_in(session).deliver_now
  # end
end

Rails.application.config.to_prepare do
  Passwordless::Session.strict_loading_by_default = false
end
