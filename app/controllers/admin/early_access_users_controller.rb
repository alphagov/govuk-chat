class Admin::EarlyAccessUsersController < Admin::BaseController
  def index
    filter_params = params.permit(:email, :page, :sort, :source, :revoked)
    @filter = Admin::Form::EarlyAccessUsersFilter.new(filter_params)
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
      @form.submit

      redirect_to admin_early_access_users_path, notice: "User created"
    else
      render :new, status: :unprocessable_entity
    end
  end

private

  def create_params
    params.require(:create_early_access_user_form).permit(:email)
  end
end
