class Admin::Form::Settings::DelayedAccessPlacesForm < Admin::Form::Settings::BaseForm
  attribute :places, :integer

  validates :places, presence: { message: "Enter the number of delayed access places to add or remove" }
  validates :places,
            numericality: { other_than: 0, message: "Enter a positive or negative integer for places." },
            if: -> { places.present? }
  validate :places_cannot_be_negative

  def submit
    validate!

    settings.locked_audited_update(user, action, author_comment) do
      delayed_access_places = [0, settings.delayed_access_places + places].max
      settings.delayed_access_places = delayed_access_places
    end
  end

private

  def action
    if places.positive?
      "Added #{places} delayed access places."
    else
      "Removed #{places * -1} delayed access places."
    end
  end

  def places_cannot_be_negative
    return if places.blank?

    new_total = settings.delayed_access_places + places
    if new_total.negative?
      errors.add(
        :places,
        "Delayed access places cannot be negative. " \
        "There are currently #{settings.delayed_access_places} places available to remove.",
      )
    end
  end
end
