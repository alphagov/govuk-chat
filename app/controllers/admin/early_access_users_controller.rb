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

  def update
    @user = EarlyAccessUser.find(params[:id])
    @form = Admin::Form::EarlyAccessUsers::UpdateForm.new(
      user: @user,
      question_limit: update_params[:question_limit].presence,
    )

    if @form.valid?
      @form.submit

      redirect_to admin_early_access_user_path(@user), notice: "User updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  def create_params
    params.require(:create_early_access_user_form).permit(:email)
  end

  def update_params
    params.require(:update_early_access_user_form).permit(:question_limit)
  end
end
