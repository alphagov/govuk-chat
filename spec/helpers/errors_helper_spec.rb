RSpec.describe ErrorsHelper do
  let(:validation_error) { "Required field" }
  let(:model_klass) do
    error_message = validation_error
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      def self.name = "GenericModel"

      attribute :required
      validates :required, presence: { message: error_message }
    end
  end

  describe "#error_items" do
    context "when a model has errors" do
      let(:model) { model_klass.new(required: nil).tap(&:validate) }

      context "when the attribute matches the error attribute" do
        it "returns an array of error hashes, each href key will anchor to the target_id" do
          expect(helper.error_items(model, :required, "#target_id"))
            .to eq([{ text: validation_error, href: "#target_id" }])
        end
      end

      context "when the attribute doesn't match the error attribute" do
        it "returns an array of error hashes, each href key will be nil" do
          expect(helper.error_items(model, :other_attr, "#target_id"))
            .to eq([{ text: validation_error, href: nil }])
        end
      end
    end

    context "when a model has no errors" do
      it "returns an empty array" do
        model = model_klass.new(required: true).tap(&:validate)

        expect(helper.error_items(model, :confirmation, "#target_id")).to eq([])
      end
    end
  end
end
