class SignonEntryController < BaseController
  skip_before_action :authorise_web_user
  skip_before_action :check_chat_web_access

  def index
    if current_user.has_permission?(SignonUser::Permissions::ADMIN_AREA)
      redirect_to admin_homepage_path
    elsif current_user.has_permission?(SignonUser::Permissions::WEB_CHAT)
      redirect_to homepage_path if check_chat_web_access.nil?
    else
      render "errors/forbidden", status: :forbidden
    end
  end
end
