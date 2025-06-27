class HomepageController < BaseController
  before_action :cache_cookieless_requests

  def index
    render :ut_landing_page
  end
end
