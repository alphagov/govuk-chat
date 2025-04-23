module Api
  class RequestValidationError < Committee::ValidationError
    def error_body
      GenericErrorBlueprint.render_as_hash(message:)
    end
  end
end
