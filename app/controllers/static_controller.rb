class StaticController < BaseController
  skip_before_action :require_early_access_user!

  before_action do
    expires_in(5.minutes, public: true) unless Rails.env.development?
    request.session_options[:skip] = true
  end
end
