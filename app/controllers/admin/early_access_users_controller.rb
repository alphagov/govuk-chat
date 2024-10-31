class Admin::EarlyAccessUsersController < Admin::BaseController
  def index
    filter_params = params.permit(:email, :page, :sort, :source, :access, :previous_sign_up_denied)
    @filter = Admin::Filters::EarlyAccessUsersFilter.new(filter_params)
  end

  def show
    @user = EarlyAccessUser.find(params[:id])
  end

  def new
    @user = EarlyAccessUser.new
    @form = Admin::Form::EarlyAccessUsers::CreateForm.new
  end

  def create
    @form = Admin::Form::EarlyAccessUsers::CreateForm.new(create_params)

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
      question_limit: @user.individual_question_limit,
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

  def delete
    @user = EarlyAccessUser.find(params[:id])
  end

  def destroy
    EarlyAccessUser.find(params[:id])
                   .destroy_with_audit(deletion_type: :admin, deleted_by_admin_user_id: current_user.id)

    redirect_to admin_early_access_users_path, notice: "User deleted"
  end

private

  def create_params
    params.require(:create_early_access_user_form).permit(:email)
  end

  def update_params
    params.require(:update_early_access_user_form).permit(:question_limit)
  end
end
