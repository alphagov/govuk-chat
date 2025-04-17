RSpec.describe Admin::Form::Settings::InstantAccessPlacesForm do
  describe "validations" do
    it "is invalid if places takes instant_access_places below 0" do
      create(:settings, instant_access_places: 10)
      form = described_class.new(places: -100)

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:places])
        .to eq(["Instant access places cannot be negative. There are currently 10 places available to remove."])
    end
  end

  describe "#submit" do
    let!(:settings) { create(:settings, instant_access_places: 10) }

    it "raises an error when the form object is invalid" do
      form = described_class.new
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "creates a settings audit with the correct attributes on successful save" do
      form = described_class.new(places: 5, author_comment: "More places.", user: build(:signon_user))

      expect { form.submit }.to change(SettingsAudit, :count).by(1)
      expect(SettingsAudit.includes(:user).last)
        .to have_attributes(
          user: form.user,
          author_comment: form.author_comment,
          action: "Added 5 instant access places",
        )
    end

    it "adds the number of instant access places to the settings instance" do
      form = described_class.new(places: 5)
      form.submit
      expect(settings.reload.instant_access_places).to eq 15
    end

    it "handles negative places correctly" do
      form = described_class.new(places: -5)

      form.submit

      expect(settings.reload.instant_access_places).to eq 5
      expect(SettingsAudit.last.action).to eq "Removed 5 instant access places"
    end

    it "sets instant access places to 0 if the result is negative as a failsafe" do
      form = described_class.new(places: -10)
      form.validate
      settings.update!(instant_access_places: 5)
      form.submit

      expect(settings.reload.instant_access_places).to eq 0
      expect(SettingsAudit.last.action).to eq "Removed 10 instant access places"
    end
  end
end
