class StaticController < BaseController
  skip_before_action :check_chat_public_access, except: %i[support]
  before_action :cache_cookieless_requests

  def support; end
end
