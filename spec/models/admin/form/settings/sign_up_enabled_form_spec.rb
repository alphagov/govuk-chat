RSpec.describe Admin::Form::Settings::SignUpEnabledForm do
  describe "#submit" do
    let!(:settings) { create(:settings, sign_up_enabled: false) }

    it "raises an error when the form object is invalid" do
      form = described_class.new(author_comment: "s" * 256)
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "creates a settings audit with the correct attributes on successful save" do
      form = described_class.new(enabled: true, author_comment: "Turning sign ups on.", user: build(:user))

      expect { form.submit }.to change(SettingsAudit, :count).by(1)
      expect(SettingsAudit.includes(:user).last)
        .to have_attributes(
          user: form.user,
          author_comment: form.author_comment,
          action: "Sign up enabled set to true",
        )
    end

    it "updates the sign up enabled setting" do
      form = described_class.new(enabled: true)
      form.submit
      expect(settings.reload.sign_up_enabled).to be true
    end

    it "doesn't persist an audit if sign_up_enabled wouldn't change" do
      form = described_class.new(enabled: false)
      expect { form.submit }.not_to change(SettingsAudit, :count)
    end
  end
end
