module JobExamples
  shared_examples "a job in queue" do |expected_queue|
    it "is enqueued to the #{expected_queue} queue" do
      expect(described_class.queue_name).to eq(expected_queue)
    end
  end

  shared_examples "a job that adheres to the auto_evaluation quota" do |metric|
    let(:answer) { create(:answer) }
    let(:beginning_of_current_hour) { Time.current.beginning_of_hour }

    it "writes the auto_evaluations_count cache key on the first evaluation" do
      freeze_time do
        described_class.new.perform(answer.id)

        key = "auto_evaluations_count_#{beginning_of_current_hour.to_i}"
        expect(Rails.cache.read(key)).to eq(1)
      end
    end

    it "increments the auto_evaluations_count cache key for subsequent evaluations" do
      freeze_time do
        key = "auto_evaluations_count_#{beginning_of_current_hour.to_i}"
        Rails.cache.write(key, 1)
        described_class.new.perform(answer.id)
        expect(Rails.cache.read(key)).to eq(2)
      end
    end

    it "logs a warning and does not perform the evaluation when quota limit is reached" do
      freeze_time do
        max_evaluations = Rails.configuration.max_auto_evaluations_per_hour
        key = "auto_evaluations_count_#{beginning_of_current_hour.to_i}"
        Rails.cache.write(key, max_evaluations)
        expect(described_class.logger)
          .to receive(:warn)
          .with("Auto-evaluation quota limit of #{max_evaluations} evaluations per hour reached")
        expect(metric).not_to receive(:call)

        described_class.new.perform(answer.id)
      end
    end

    it "uses a new cache key after the hour changes" do
      beginning_of_current_hour = Time.current.beginning_of_hour

      travel_to(beginning_of_current_hour) do
        described_class.new.perform(answer.id)
        key = "auto_evaluations_count_#{beginning_of_current_hour.to_i}"
        expect(Rails.cache.read(key)).to eq(1)
      end

      travel_to(beginning_of_current_hour + 30.minutes) do
        answer_in_same_hour = create(:answer)
        described_class.new.perform(answer_in_same_hour.id)
        key = "auto_evaluations_count_#{beginning_of_current_hour.to_i}"
        expect(Rails.cache.read(key)).to eq(2)
      end

      travel_to(beginning_of_current_hour + 1.hour) do
        answer_in_next_hour = create(:answer)
        described_class.new.perform(answer_in_next_hour.id)
        key = "auto_evaluations_count_#{(beginning_of_current_hour + 1.hour).to_i}"
        expect(Rails.cache.read(key)).to eq(1)
      end
    end

    it "expires the cache key an hour after the last evaluation" do
      described_class.new.perform(answer.id)
      key = "auto_evaluations_count_#{beginning_of_current_hour.to_i}"
      expect(Rails.cache.read(key)).to eq(1)

      travel 1.hour + 1.minute do
        expect(Rails.cache.read(key)).to be_nil
      end
    end
  end

  shared_examples "a job that retries on errors" do |error_class|
    let(:answer) { create(:answer) }
    it "retries the job the max number of times on #{error_class}" do
      described_class.perform_later(answer.id)

      assert_performed_jobs described_class::MAX_RETRIES do
        expect { perform_enqueued_jobs }
          .to raise_error(error_class)
      end
    end
  end
end
