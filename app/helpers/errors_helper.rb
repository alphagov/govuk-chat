module ErrorsHelper
  def error_items(model, attribute, target_id)
    model.errors.map do |error|
      href = error.attribute == attribute ? target_id : nil
      { text: error.message, href: }
    end
  end
end
