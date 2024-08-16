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
    @form = Admin::Form::WaitingListUserForm.new
  end

  def create
    @form = Admin::Form::WaitingListUserForm.new(user_params)

    if @form.valid?
      user = @form.submit

      redirect_to admin_waiting_list_user_path(user), notice: "User created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = WaitingListUser.find(params[:id])
    @form = Admin::Form::WaitingListUserForm.new(
      user: @user,
      email: @user.email,
      user_description: @user.user_description,
      reason_for_visit: @user.reason_for_visit,
    )
  end

  def update
    @user = WaitingListUser.find(params[:id])
    @form = Admin::Form::WaitingListUserForm.new(
      user: @user,
      **user_params,
    )

    if @form.valid?
      @form.submit
      redirect_to admin_waiting_list_user_path(@user), notice: "User updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def delete
    @user = WaitingListUser.find(params[:id])
  end

  def destroy
    user = WaitingListUser.find(params[:id])

    user.destroy!

    redirect_to admin_waiting_list_users_path, notice: "User deleted"
  end

private

  def user_params
    params
      .require(:waiting_list_user_form)
      .permit(:email, :user_description, :reason_for_visit)
  end
end
