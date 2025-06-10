RSpec.describe Admin::Form::Settings::ApiAccessForm do
  describe "#submit" do
    it "updates the settings api_access_enabled attribute" do
      settings = create(:settings, api_access_enabled: true)
      form = described_class.new(enabled: false)
      expect { form.submit }
        .to change { settings.reload.api_access_enabled }.to(false)
    end

    it "doesn't persist an audit if api_access_enabled isn't changed" do
      create(:settings, api_access_enabled: false)
      form = described_class.new(enabled: false)
      expect { form.submit }.not_to change(SettingsAudit, :count)
    end

    it "mentions API access in the action when disabling api access" do
      create(:settings, api_access_enabled: true)
      described_class.new(enabled: false).submit
      expect(SettingsAudit.last.action).to eq("API access enabled set to false")
    end
  end
end
