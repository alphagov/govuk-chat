class Admin::WaitingListUsersController < Admin::BaseController
  def index
    filter_params = params.permit(:email, :page, :sort)
    @filter = Admin::Filters::PilotUsers::WaitingListUsersFilter.new(filter_params)
  end
end
