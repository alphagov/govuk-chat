class HomepageController < BaseController
  before_action :cache_cookieless_requests
end
