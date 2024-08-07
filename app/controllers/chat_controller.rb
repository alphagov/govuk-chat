class ChatController < BaseController
  def index
    expires_in(5.minutes, public: true) unless Rails.env.development?
    early_access_auth = !Rails.configuration.available_without_early_access_authentication
    render early_access_auth ? :index_early_access : :index_not_early_access
  end
end
