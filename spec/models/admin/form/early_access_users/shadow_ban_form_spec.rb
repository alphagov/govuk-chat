RSpec.describe Admin::Form::EarlyAccessUsers::ShadowBanForm do
  let(:user) { create(:early_access_user, :restored) }

  describe "validations" do
    it "returns true when valid" do
      form = described_class.new(user:, shadow_ban_reason: "Asking too many questions")
      expect(form).to be_valid
    end

    it "returns false when the reason is missing" do
      form = described_class.new(user:)

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:shadow_ban_reason]).to eq(["Enter a reason for shadow banning the user"])
    end

    it "returns false when the reason has too many characters" do
      form = described_class.new(
        user:,
        shadow_ban_reason: "a" * (Admin::Form::EarlyAccessUsers::ShadowBanForm::SHADOW_BAN_REASON_LENGTH_MAXIMUM + 1),
      )

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:shadow_ban_reason])
        .to eq([
          sprintf(
            described_class::SHADOW_BAN_REASON_LENGTH_ERROR_MESSAGE,
            count: described_class::SHADOW_BAN_REASON_LENGTH_MAXIMUM,
          ),
        ])
    end
  end

  describe "#submit" do
    it "raises an error when the form object is invalid" do
      form = described_class.new(user:)
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "updates and resets the relevant attributes" do
      freeze_time do
        form = described_class.new(user:, shadow_ban_reason: "Asking too many questions")
        expect { form.submit }
          .to change(user, :shadow_banned_reason).to("Asking too many questions")
          .and change(user, :shadow_banned_at).to(Time.zone.now)
          .and change(user, :restored_at).to(nil)
          .and change(user, :restored_reason).to(nil)
      end
    end
  end
end
