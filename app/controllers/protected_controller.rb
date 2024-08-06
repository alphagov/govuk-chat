class ProtectedController < EarlyAccessController
  before_action :require_user!

  def index; end
end
