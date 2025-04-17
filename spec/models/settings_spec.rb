RSpec.describe Settings do
  describe "validations" do
    it "validates singleton_guard is 0" do
      valid_instance = build(:settings, singleton_guard: 0)
      invalid_instance = build(:settings, singleton_guard: 1)

      expect(valid_instance).to be_valid
      expect { invalid_instance.valid? }.to raise_error(ActiveModel::StrictValidationFailed)
    end
  end

  describe ".instance" do
    it "returns the first settings record if one is present" do
      instance = create(:settings)
      expect(described_class.instance).to eq(instance)
    end

    it "creates a new settings record if one is not present" do
      expect { described_class.instance }.to change(described_class, :count).by(1)
    end
  end

  describe "#locked_audited_update" do
    let(:audit_user) { build(:signon_user) }
    let(:audit_action) { "Added 5 instant access places." }
    let(:audit_comment) { "We've run out of places so it's time to add more." }
    let(:call_locked_audit_update) do
      settings.locked_audited_update(
        audit_user,
        audit_action,
        audit_comment,
      ) do
        settings.instant_access_places += 5
      end
    end
    let(:settings) { create(:settings, instant_access_places: 5) }

    it "locks the settings instance to cope with concurrent edits" do
      expect(settings).to receive(:with_lock).and_call_original
      call_locked_audit_update
      expect(settings.reload.instant_access_places).to eq(10)
    end

    it "persists a settings audit based on the arguments passed in" do
      expect { call_locked_audit_update }
        .to change(SettingsAudit, :count).by(1)
        .and change { settings.reload.instant_access_places }.by(5)
      expect(SettingsAudit.includes(:user).last).to have_attributes(
        user: audit_user,
        action: audit_action,
        author_comment: audit_comment,
      )
    end
  end
end
