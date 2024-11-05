RSpec.describe Admin::Form::EarlyAccessUsers::RestoreAccessForm do
  let(:user) { create(:early_access_user, :shadow_banned, :revoked) }

  describe "validations" do
    it "returns true when valid" do
      form = described_class.new(user:, restored_reason: "Giving them a second chance.")
      expect(form).to be_valid
    end

    it "returns false when the reason is missing" do
      form = described_class.new(user:)

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:restored_reason])
        .to eq([described_class::RESTORED_REASON_PRESENCE_ERROR_MESSAGE])
    end

    it "returns false when the reason has too many characters" do
      form = described_class.new(
        user:, restored_reason: "a" * (described_class::RESTORED_REASON_LENGTH_MAXIMUM + 1),
      )

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:restored_reason])
        .to eq([
          sprintf(
            described_class::RESTORED_REASON_LENGTH_ERROR_MESSAGE,
            count: described_class::RESTORED_REASON_LENGTH_MAXIMUM,
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
        form = described_class.new(user:, restored_reason: "Giving them a second chance.")
        expect { form.submit }
          .to change(user, :restored_at).to(Time.zone.now)
          .and change(user, :restored_reason).to("Giving them a second chance.")
          .and change(user, :revoked_at).to(nil)
          .and change(user, :revoked_reason).to(nil)
          .and change(user, :shadow_banned_at).to(nil)
          .and change(user, :shadow_banned_reason).to(nil)
          .and change(user, :bannable_action_count).to(0)
      end
    end
  end
end
