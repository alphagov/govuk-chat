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
end
