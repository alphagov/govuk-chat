class Admin::Form::Settings::InstantAccessPlacesForm < Admin::Form::Settings::BaseForm
  attribute :places, :integer

  validates :places, presence: { message: "Enter the number of instant access places to add or remove" }
  validates :places,
            numericality: { other_than: 0, message: "Enter a positive or negative integer for places." },
            if: -> { places.present? }
  validate :places_cannot_be_negative

  def submit
    validate!

    settings.locked_audited_update(user, action, author_comment) do
      instant_access_places = [0, settings.instant_access_places + places].max
      settings.instant_access_places = instant_access_places
    end
  end

private

  def action
    if places.positive?
      "Added #{places} instant access places."
    else
      "Removed #{places * -1} instant access places."
    end
  end

  def places_cannot_be_negative
    return if places.blank?

    new_total = settings.instant_access_places + places
    if new_total.negative?
      errors.add(
        :places,
        "Instant access places cannot be negative. " \
        "There are currently #{settings.instant_access_places} places available to remove.",
      )
    end
  end
end
