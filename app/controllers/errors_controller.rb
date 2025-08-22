class ErrorsController < BaseController
  skip_before_action :verify_authenticity_token
  skip_before_action :ensure_signon_user_if_required
  skip_before_action :check_chat_web_access
  skip_before_action :authorise_web_user
  after_action { response.headers["No-Fallback"] = "true" }

  def bad_request
    respond_to do |format|
      format.json do
        render json: GenericErrorBlueprint.render(message: "Bad request"),
               status: :bad_request
      end
      format.any { render status: :bad_request, formats: :html }
    end
  end

  def forbidden
    respond_to do |format|
      format.json do
        render json: GenericErrorBlueprint.render(message: "Forbidden"),
               status: :forbidden
      end
      format.any { render status: :forbidden, formats: :html }
    end
  end

  def not_found
    respond_to do |format|
      format.json do
        render json: GenericErrorBlueprint.render(message: "Not found"),
               status: :not_found
      end
      format.any { render status: :not_found, formats: :html }
    end
  end

  def unprocessable_content
    respond_to do |format|
      format.json do
        render json: GenericErrorBlueprint.render(message: "Unprocessable content"),
               status: :unprocessable_content
      end
      format.any { render status: :unprocessable_content, formats: :html }
    end
  end

  def too_many_requests
    respond_to do |format|
      format.json do
        render json: GenericErrorBlueprint.render(message: "Too many requests"),
               status: :too_many_requests
      end
      format.any { render status: :too_many_requests, formats: :html }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.json do
        render json: GenericErrorBlueprint.render(message: "Internal server error"),
               status: :internal_server_error
      end
      format.any { render status: :internal_server_error, formats: :html }
    end
  end
end
