class ValidationErrorBlueprint < Blueprinter::Base
  field :errors
  field :message do
    "Unprocessable content"
  end
end
