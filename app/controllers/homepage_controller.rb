class HomepageController < BaseController
  skip_before_action :ensure_early_access_user_if_required
  skip_forgery_protection # as we cache the form we can't verify the token
  before_action :cache_if_not_logged_in, only: :index

  def index
    render :index
  end
end
