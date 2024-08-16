class Admin::WaitingListUsersController < Admin::BaseController
  def index
    filter_params = params.permit(:email, :page, :sort)
    @filter = Admin::Filters::WaitingListUsersFilter.new(filter_params)
  end

  def show
    @user = WaitingListUser.find(params[:id])
  end

  def new
    @user = WaitingListUser.new
    @form = Admin::Form::WaitingListUsers::CreateWaitingListUserForm.new
  end

  def create
    @form = Admin::Form::WaitingListUsers::CreateWaitingListUserForm.new(create_params)

    if @form.valid?
      user = @form.submit

      redirect_to admin_waiting_list_user_path(user), notice: "User created"
    else
      render :new, status: :unprocessable_entity
    end
  end

private

  def create_params
    params
      .require(:create_waiting_list_user_form)
      .permit(:email, :user_description, :reason_for_visit)
  end
end
