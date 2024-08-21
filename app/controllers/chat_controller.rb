class ChatController < BaseController
  skip_before_action :require_early_access_user!
  after_action { request.session_options[:skip] = true }

  def index
    expires_in(5.minutes, public: true) unless Rails.env.development?
    early_access_auth = !Rails.configuration.available_without_early_access_authentication
    render early_access_auth ? :index_early_access : :index_not_early_access
  end
end
