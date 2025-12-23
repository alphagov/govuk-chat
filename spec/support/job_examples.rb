module JobExamples
  shared_examples "a job in queue" do |expected_queue|
    it "is enqueued to the #{expected_queue} queue" do
      expect(described_class.queue_name).to eq(expected_queue)
    end
  end

  shared_examples "a job that adheres to the metric quota" do |metric|
    let(:answer) { create(:answer) }

    before { allow(Rails.configuration).to receive(:max_auto_evaluation_metrics_per_hour).and_return(2) }

    it "writes the auto_evaluation_metrics_run_count cache key on the first metric run" do
      expect(Rails.cache).to receive(:write)
                         .with("auto_evaluation_metrics_run_count", 1, expires_in: 1.hour)

      described_class.new.perform(answer.id)
    end

    it "increments the auto_evaluation_metrics_run_count cache key in subsequent runs" do
      allow(Rails.cache).to receive(:read).with("auto_evaluation_metrics_run_count").and_return(1)
      expect(Rails.cache).to receive(:increment)
                         .with("auto_evaluation_metrics_run_count")

      described_class.new.perform(answer.id)
    end

    it "logs info and does not perform evaluation when quota limit is reached" do
      allow(Rails.cache).to receive(:read).with("auto_evaluation_metrics_run_count").and_return(2)
      expect(described_class.logger)
        .to receive(:warn)
        .with("Auto-evaluation quota limit of 2 metrics per hour reached")
      expect(metric).not_to receive(:call)

      described_class.new.perform(answer.id)
    end
  end

  shared_examples "a job that retries on service errors" do |error_class|
    let(:answer) { create(:answer) }
    it "retries the job the max number of times on #{error_class}" do
      (described_class::MAX_RETRIES - 1).times do
        described_class.perform_later(answer.id)
        expect { perform_enqueued_jobs }.not_to raise_error
      end

      described_class.perform_later(answer.id)
      expect { perform_enqueued_jobs }.to raise_error(error_class)
    end
  end
end
