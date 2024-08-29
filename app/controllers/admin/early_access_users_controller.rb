class Admin::EarlyAccessUsersController < Admin::BaseController
  def index
    filter_params = params.permit(:email, :page, :sort, :source, :revoked)
    @filter = Admin::Filters::EarlyAccessUsersFilter.new(filter_params)
  end

  def show
    @user = EarlyAccessUser.find(params[:id])
  end

  def new
    @user = EarlyAccessUser.new
    @form = Admin::Form::EarlyAccessUsers::CreateEarlyAccessUserForm.new
  end

  def create
    @form = Admin::Form::EarlyAccessUsers::CreateEarlyAccessUserForm.new(create_params)

    if @form.valid?
      user = @form.submit

      redirect_to admin_early_access_user_path(user), notice: "User created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = EarlyAccessUser.find(params[:id])
    @form = Admin::Form::EarlyAccessUsers::UpdateForm.new(
      user: @user,
      question_limit: @user.question_limit,
    )
  end

private

  def create_params
    params.require(:create_early_access_user_form).permit(:email)
  end
end
