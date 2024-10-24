class Admin::Form::Settings::MaxWaitingListPlacesForm < Admin::Form::Settings::BaseForm
  attribute :max_places, :integer

  validates :max_places, presence: { message: "Enter the maximum number of waiting list places" }
  validates :max_places,
            numericality: { greater_than: 0, message: "Enter a positive integer for the maximum number of waiting list places" },
            if: -> { max_places.present? }

  def submit
    validate!
    return if max_places == settings.max_waiting_list_places

    settings.locked_audited_update(user, "Updated maximum waiting list places to #{max_places}", author_comment) do
      settings.max_waiting_list_places = max_places
    end
  end
end
