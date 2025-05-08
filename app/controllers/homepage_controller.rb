class HomepageController < BaseController
  skip_forgery_protection # as we cache the form we can't verify the token
  before_action :cache_if_not_logged_in, only: :index

  def index
    render :index
  end
end
