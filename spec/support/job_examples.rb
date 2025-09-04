module JobExamples
  shared_examples "a job in queue" do |expected_queue|
    it "is enqueued to the #{expected_queue} queue" do
      expect(described_class.queue_name).to eq(expected_queue)
    end
  end
end
