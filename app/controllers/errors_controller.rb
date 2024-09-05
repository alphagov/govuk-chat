class ErrorsController < BaseController
  skip_before_action :verify_authenticity_token
  skip_before_action :ensure_signon_user_if_required
  skip_before_action :ensure_early_access_user_if_required

  def bad_request
    render status: :bad_request, formats: :html
  end

  def forbidden
    render status: :forbidden, formats: :html
  end

  def not_found
    render status: :not_found, formats: :html
  end

  def unprocessable_entity
    render status: :unprocessable_entity, formats: :html
  end

  def internal_server_error
    render status: :internal_server_error, formats: :html
  end
end
