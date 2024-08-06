class Admin::Form::Settings::InstantAccessPlacesForm < Admin::Form::Settings::PlacesForm
  validate -> { places_cannot_be_negative(:instant_access_places) }

  def submit
    validate!

    settings.locked_audited_update(user, action("instant access places"), author_comment) do
      instant_access_places = [0, settings.instant_access_places + places].max
      settings.instant_access_places = instant_access_places
    end
  end
end
