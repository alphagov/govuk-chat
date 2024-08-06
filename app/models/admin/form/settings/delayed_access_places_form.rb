class Admin::Form::Settings::DelayedAccessPlacesForm < Admin::Form::Settings::PlacesForm
  validate -> { places_cannot_be_negative(:delayed_access_places) }

  def submit
    validate!

    settings.locked_audited_update(user, action("delayed access places"), author_comment) do
      delayed_access_places = [0, settings.delayed_access_places + places].max
      settings.delayed_access_places = delayed_access_places
    end
  end
end
