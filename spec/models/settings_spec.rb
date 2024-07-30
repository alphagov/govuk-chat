RSpec.describe Settings do
  describe "validations" do
    it "validates singleton_guard is 0" do
      valid_instance = build(:settings, singleton_guard: 0)
      invalid_instance = build(:settings, singleton_guard: 1)

      expect(valid_instance).to be_valid
      expect { invalid_instance.valid? }.to raise_error(ActiveModel::StrictValidationFailed)
    end
  end
end
