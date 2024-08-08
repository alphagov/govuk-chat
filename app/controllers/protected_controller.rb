class ProtectedController < BaseController
  before_action :require_early_access_user!
end
