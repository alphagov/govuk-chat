module ErrorsHelper
  def error_items_for_summary_component(model, anchor_mappings = {})
    model.errors.map do |error|
      href = anchor_mappings[error.attribute]
      { text: error.message, href: }
    end
  end

  def error_items(model, attribute)
    model.errors[attribute].map { |message| { text: message } }
  end
end
