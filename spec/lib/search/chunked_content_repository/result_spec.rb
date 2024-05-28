RSpec.describe Search::ChunkedContentRepository::Result do
  describe ".new" do
    it "defaults missing members to nil" do
      defaults = described_class.members.index_with(nil)
      values = defaults.merge({ _id: "id", content_id: SecureRandom.uuid, locale: "en", base_path: "/path" })

      expect(described_class.new(**values)).to have_attributes(values)
    end

    it "doesn't raise an error if any members are missing from the keyword arguments" do
      expect { described_class.new }.not_to raise_error
    end

    it "raises when given keyword arguments that aren't members" do
      expect { described_class.new(made_up_arg: "hi") }.to raise_error(ArgumentError)
    end
  end
end
