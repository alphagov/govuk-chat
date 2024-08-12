class Admin::EarlyAccessUsersController < Admin::BaseController
  def index
    render plain: "Early access users"
  end
end
