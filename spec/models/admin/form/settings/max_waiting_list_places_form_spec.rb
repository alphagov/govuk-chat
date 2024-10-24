RSpec.describe Admin::Form::Settings::MaxWaitingListPlacesForm do
  describe "validations" do
    it "is invalid if max_places is blank" do
      form = described_class.new(max_places: "")

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:max_places])
        .to eq(["Enter the maximum number of waiting list places"])
    end

    it "is invalid if max_places is not a positive integer" do
      [0, -1].each do |max_places|
        form = described_class.new(max_places:)
        expect(form).to be_invalid
        expect(form.errors.count).to eq(1)
        expect(form.errors.messages[:max_places])
          .to eq(["Enter a positive integer for the maximum number of waiting list places"])
      end
    end
  end

  describe "#submit" do
    let!(:settings) { create(:settings, max_waiting_list_places: 10) }

    it "raises an error when the form object is invalid" do
      form = described_class.new
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "creates a settings audit with the correct attributes on successful save" do
      form = described_class.new(max_places: 15, author_comment: "More places.", user: build(:admin_user))

      expect { form.submit }.to change(SettingsAudit, :count).by(1)
      expect(SettingsAudit.includes(:user).last)
        .to have_attributes(
          user: form.user,
          author_comment: form.author_comment,
          action: "Updated maximum waiting list places to 15",
        )
    end

    it "updates the settings max_waiting_list_places to the places attibute" do
      form = described_class.new(max_places: 15)
      form.submit
      expect(settings.reload.max_waiting_list_places).to eq 15
    end

    it "doesn't create an audit if the max places value doesn't change" do
      form = described_class.new(max_places: 10)
      expect { form.submit }.not_to change(SettingsAudit, :count)
    end
  end
end
