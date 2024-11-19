class StaticController < BaseController
  skip_before_action :ensure_early_access_user_if_required
  skip_before_action :check_chat_public_access

  before_action do
    next if Rails.env.development? || current_early_access_user

    expires_in(1.minute, public: true)
    add_cookie_to_vary_header
  end
end
