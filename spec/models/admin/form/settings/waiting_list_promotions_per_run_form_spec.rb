RSpec.describe Admin::Form::Settings::WaitingListPromotionsPerRunForm do
  describe "validations" do
    it "is invalid if promotions_per_run is blank" do
      form = described_class.new(promotions_per_run: "")

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:promotions_per_run])
        .to eq(["Enter the number of promotions per run"])
    end

    it "is invalid if promotions_per_run is not between 0 and 200" do
      [-1, 201].each do |promotions_per_run|
        form = described_class.new(promotions_per_run:)
        expect(form).to be_invalid
        expect(form.errors.count).to eq(1)
        expect(form.errors.messages[:promotions_per_run])
          .to eq(["Enter an integer between 0 and 200 for promotions per run"])
      end
    end
  end

  describe "#submit" do
    let!(:settings) { create(:settings, waiting_list_promotions_per_run: 25) }

    it "raises an error when the form object is invalid" do
      form = described_class.new
      expect { form.submit }.to raise_error(ActiveModel::ValidationError)
    end

    it "creates a settings audit with the correct attributes on successful save" do
      signon_user = build(:signon_user)
      form = described_class.new(promotions_per_run: 15,
                                 author_comment: "Less promotions please.",
                                 user: signon_user)

      expect { form.submit }.to change(SettingsAudit, :count).by(1)
      expect(SettingsAudit.includes(:user).last)
        .to have_attributes(
          user: signon_user,
          author_comment: "Less promotions please.",
          action: "Updated waiting list promotions per run to 15",
        )
    end

    it "updates the settings waiting_list_promotions_per_run to the promotions_per_run attibute" do
      form = described_class.new(promotions_per_run: 15)
      expect { form.submit }
        .to change { settings.reload.waiting_list_promotions_per_run }.to(15)
    end

    it "doesn't create an audit if the promotions_per_run value doesn't change" do
      form = described_class.new(promotions_per_run: 25)
      expect { form.submit }.not_to change(SettingsAudit, :count)
    end
  end
end
