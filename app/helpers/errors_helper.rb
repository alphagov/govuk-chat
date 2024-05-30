module ErrorsHelper
  def error_items(model, attributes = {})
    model.errors.map do |error|
      href = anchor_mappings[error.attribute]
      { text: error.message, href: }
    end
  end
end
