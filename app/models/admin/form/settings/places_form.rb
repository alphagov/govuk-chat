class Admin::Form::Settings::PlacesForm < Admin::Form::Settings::BaseForm
  attribute :places, :integer

  validates :places, presence: { message: "Enter the number of places to add or remove" }
  validates :places,
            numericality: { other_than: 0, message: "Enter a positive or negative integer for places." },
            if: -> { places.present? }

private

  def action(setting)
    if places.positive?
      "Added #{places} #{setting}."
    else
      "Removed #{places * -1} #{setting}."
    end
  end

  def places_cannot_be_negative(attribute)
    return if places.blank?

    new_total = settings.public_send(attribute) + places
    if new_total.negative?
      errors.add(
        :places,
        "#{attribute.to_s.humanize} cannot be negative. " \
        "There are currently #{settings.public_send(attribute)} places available to remove.",
      )
    end
  end
end
