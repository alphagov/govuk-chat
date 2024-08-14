RSpec.describe Admin::Form::EarlyAccessUsers::RevokeAccessForm do
  let(:user) { create(:early_access_user) }

  describe "validations" do
    it "returns false when the reason is missing" do
      form = described_class.new(user:)

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:revoke_reason]).to eq(["Enter a reason for revoking access"])
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new(user:)
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "updates the relevant attributes" do
      freeze_time do
        form = described_class.new(user:, revoke_reason: "Asking too many questions")
        expect { form.submit }
          .to change(user, :revoked_reason).to("Asking too many questions")
          .and change(user, :revoked_at).to(Time.zone.now)
      end
    end
  end
end
