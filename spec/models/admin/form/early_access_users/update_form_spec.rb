RSpec.describe Admin::Form::EarlyAccessUsers::UpdateForm do
  describe "validations" do
    it "returns false if the question limit is invalid" do
      form = described_class.new(user: build(:early_access_user), question_limit: "invalid", bannable_action_count: 0)

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:question_limit]).to eq(["Question limit must be a number or blank"])
    end

    it "returns false if the bannable action count is invalid" do
      form = described_class.new(user: build(:early_access_user), bannable_action_count: "invalid", question_limit: 1)

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:bannable_action_count]).to eq(["Bannable action count must be a number"])
    end
  end

  describe "#submit" do
    let(:user) { create(:early_access_user, individual_question_limit: 5, bannable_action_count: 1) }

    it "raises an error when the form object is invalid" do
      form = described_class.new(user: build(:early_access_user), question_limit: "invalid")
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "updates the users bannable action count" do
      form = described_class.new(user:, question_limit: 5, bannable_action_count: 0)
      expect { form.submit }.to change(user, :bannable_action_count).to(0)
    end

    context "when updating the question limit" do
      it "sets the value to null if the question limit matches the default" do
        allow(Rails.configuration.conversations).to receive(:max_questions_per_user).and_return(10)
        form = described_class.new(user:, question_limit: 10, bannable_action_count: 1)
        expect { form.submit }.to change(user, :individual_question_limit).from(5).to(nil)
      end

      it "sets the value to null if the question limit is blank" do
        form = described_class.new(user:, question_limit: nil, bannable_action_count: 1)
        expect { form.submit }.to change(user, :individual_question_limit).from(5).to(nil)
      end

      it "sets the value to the value specified" do
        form = described_class.new(user:, question_limit: 10, bannable_action_count: 1)
        expect { form.submit }.to change(user, :individual_question_limit).from(5).to(10)
      end
    end
  end
end
