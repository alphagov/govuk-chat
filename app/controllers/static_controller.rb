class StaticController < BaseController
  skip_before_action :check_chat_web_access
  before_action :cache_cookieless_requests
end
