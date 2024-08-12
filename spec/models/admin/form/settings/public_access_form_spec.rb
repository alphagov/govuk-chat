RSpec.describe Admin::Form::Settings::PublicAccessForm do
  describe "valid?" do
    it "returns false when given a downtime_type that isn't expected" do
      form = described_class.new(downtime_type: "not_in_list")
      expect(form.valid?).to be(false)
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new(downtime_type: "not_in_list")
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "update the settings public_access_enabled and downtime_type attributes" do
      settings = create(:settings, public_access_enabled: true, downtime_type: :permanent)
      form = described_class.new(enabled: false, downtime_type: :temporary)
      expect { form.submit }
        .to change { settings.reload.public_access_enabled }.to(false)
        .and change { settings.reload.downtime_type }.to("temporary")
    end

    it "doesn't persist an audit if public_access_enabled and downtime_type aren't changed" do
      create(:settings, public_access_enabled: false, downtime_type: :temporary)
      form = described_class.new(enabled: false, downtime_type: :temporary)
      expect { form.submit }.not_to change(SettingsAudit, :count)
    end

    it "mentions public access and downtime type in the action when disabling public access" do
      create(:settings, public_access_enabled: true, downtime_type: :temporary)
      described_class.new(enabled: false, downtime_type: :temporary).submit
      expect(SettingsAudit.last.action).to eq("Public access enabled set to false, downtime type temporary")
    end

    it "mentions only public access in the action when enabling public access" do
      create(:settings, public_access_enabled: false, downtime_type: :temporary)
      described_class.new(enabled: true, downtime_type: :permanent).submit
      expect(SettingsAudit.last.action).to eq("Public access enabled set to true")
    end

    it "mentions only downtime type in the action when not changing public access" do
      create(:settings, public_access_enabled: true, downtime_type: :temporary)
      described_class.new(enabled: true, downtime_type: :permanent).submit
      expect(SettingsAudit.last.action).to eq("Downtime type set to permanent")
    end
  end
end
