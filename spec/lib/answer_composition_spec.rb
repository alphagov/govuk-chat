RSpec.describe AnswerComposition do
  describe "#monotonic_time" do
    it "returns the time" do
      allow(Process)
        .to receive(:clock_gettime)
        .and_return(83_804.50095)

      expect(described_class.monotonic_time).to eq(83_804.50095)
    end
  end
end
