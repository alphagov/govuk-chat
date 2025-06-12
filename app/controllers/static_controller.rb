class StaticController < BaseController
  skip_before_action :check_chat_web_access, except: %i[support]
  before_action :cache_cookieless_requests

  def support; end
end
