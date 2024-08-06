RSpec.describe Admin::Form::Settings::PlacesForm do
  describe "validations" do
    it "is invalid when places is not present" do
      form = described_class.new

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:places]).to eq(["Enter the number of places to add or remove"])
    end

    it "is invalid when places is 0" do
      form = described_class.new(places: 0)

      expect(form).to be_invalid
      expect(form.errors.count).to eq(1)
      expect(form.errors.messages[:places]).to eq(["Enter a positive or negative integer for places."])
    end
  end
end
