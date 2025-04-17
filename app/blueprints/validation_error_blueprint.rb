class ValidationErrorBlueprint < Blueprinter::Base
  field :errors
  field :message do
    "Unprocessable entity"
  end
end
