class Admin::EarlyAccessUsersController < Admin::BaseController
  def index
    filter_params = params.permit(:email, :page, :sort)
    @filter = Admin::Form::EarlyAccessUsersFilter.new(filter_params)
  end
end
