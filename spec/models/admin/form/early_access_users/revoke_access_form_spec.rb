RSpec.describe Admin::Form::EarlyAccessUsers::RevokeAccessForm do
  let(:user) { create(:early_access_user) }

  describe "validations" do
    it "returns true when valid" do
      form = described_class.new(user:, revoke_reason: "Asking too many questions")
      expect(form).to be_valid
    end

    it "returns false when the reason is missing" do
      form = described_class.new(user:)

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:revoke_reason])
        .to eq([described_class::REVOKE_REASON_PRESENCE_ERROR_MESSAGE])
    end

    it "returns false when the reason has too many characters" do
      form = described_class.new(
        user:,
        revoke_reason: "a" * (described_class::REVOKE_REASON_LENGTH_MAXIMUM + 1),
      )

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:revoke_reason])
        .to eq([
          sprintf(
            described_class::REVOKE_REASON_LENGTH_ERROR_MESSAGE,
            count: described_class::REVOKE_REASON_LENGTH_MAXIMUM,
          ),
        ])
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
