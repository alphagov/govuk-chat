RSpec.describe ErrorsHelper do
  let(:validation_error) { "Required field" }
  let(:model_klass) do
    error_message = validation_error
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      def self.name = "GenericModel"

      attribute :required
      attribute :also_required
      validates :required, presence: { message: error_message }
      validates :also_required, presence: { message: error_message }
    end
  end

  describe "#error_items_for_summary_component" do
    context "when a model has errors" do
      let(:model) { model_klass.new(required: nil, also_required: true).tap(&:validate) }

      context "when the attribute matches the error attribute" do
        it "returns an array of error hashes, each href key will anchor to the target_id" do
          expect(helper.error_items_for_summary_component(model, required: "#target_id"))
            .to eq([{ text: validation_error, href: "#target_id" }])
        end
      end

      context "when multiple attributes are passed in" do
        it "returns an array of error hashes with the correct target_ids" do
          model.also_required = nil
          model.validate

          expect(helper.error_items_for_summary_component(model, { required: "#target_id", also_required: "#second_target_id" }))
            .to eq([{ text: validation_error, href: "#target_id" }, { text: validation_error, href: "#second_target_id" }])
        end
      end

      context "when the attribute doesn't match the error attribute" do
        it "returns an array of error hashes, each href key will be nil" do
          expect(helper.error_items_for_summary_component(model, other_attr: "#target_id"))
            .to eq([{ text: validation_error, href: nil }])
        end
      end
    end

    context "when a model has no errors" do
      it "returns an empty array" do
        model = model_klass.new(required: true, also_required: true).tap(&:validate)

        expect(helper.error_items_for_summary_component(model, confirmation: "#target_id")).to eq([])
      end
    end
  end

  describe "#error_items" do
    context "when a model has errors" do
      let(:model) { model_klass.new(required: nil, also_required: true).tap(&:validate) }

      context "when the attribute matches the error attribute" do
        it "returns an array of error hashes" do
          expect(helper.error_items(model, :required)).to eq([{ text: validation_error }])
        end
      end

      context "when the attribute doesn't match the error attribute" do
        it "returns an empty array" do
          expect(helper.error_items(model, :other_attr)).to eq([])
        end
      end
    end

    context "when a model has no errors" do
      it "returns an empty array" do
        model = model_klass.new(required: true, also_required: true).tap(&:validate)

        expect(helper.error_items(model, :required)).to eq([])
      end
    end
  end
end
