RSpec.describe Admin::Form::Settings::WebAccessForm do
  describe "valid?" do
    it "returns false when invalid" do
      form = described_class.new(author_comment: "a" * 256)
      expect(form.valid?).to be(false)
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new(author_comment: "a" * 256)
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "updates the settings public_access_enabled" do
      settings = create(:settings, public_access_enabled: true)
      form = described_class.new(enabled: false)
      expect { form.submit }
        .to change { settings.reload.public_access_enabled }.to(false)
    end

    it "doesn't persist an audit if public_access_enabled isn't changed" do
      create(:settings, public_access_enabled: false)
      form = described_class.new(enabled: false)
      expect { form.submit }.not_to change(SettingsAudit, :count)
    end

    it "mentions public access in the action when disabling public access" do
      create(:settings, public_access_enabled: true)
      described_class.new(enabled: false).submit
      expect(SettingsAudit.last.action).to eq("Public access enabled set to false")
    end
  end
end
