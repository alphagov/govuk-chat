class StaticController < BaseController
  skip_before_action :ensure_early_access_user_if_auth_required!
  skip_before_action :check_chat_public_access

  before_action { expires_in(5.minutes, public: true) unless Rails.env.development? }
end
