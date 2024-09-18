class StaticController < BaseController
  skip_before_action :ensure_early_access_user_if_required
  skip_before_action :check_chat_public_access

  before_action do
    next if Rails.env.development? || current_early_access_user

    expires_in(1.minute, public: true)
    # a Vary of Cookie is controversial as a clients cookies can vary so much,
    # we can use it here as our CDN strips all cookies unless a session cookie
    # is available - so it effectively would only cache for cookieless requests
    response.headers["vary"] = [response.headers["vary"], "Cookie"].compact.join(", ")
  end
end
