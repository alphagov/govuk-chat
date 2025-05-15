class StaticController < BaseController
  skip_before_action :check_chat_public_access, except: %i[support]
  before_action :cache_if_not_logged_in

  def support; end
end
