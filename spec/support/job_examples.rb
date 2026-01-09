module JobExamples
  shared_examples "a job in queue" do |expected_queue|
    it "is enqueued to the #{expected_queue} queue" do
      expect(described_class.queue_name).to eq(expected_queue)
    end
  end

  shared_examples "a job that adheres to the auto_evaluation quota" do |evaluation_class|
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
        expect(evaluation_class).not_to receive(:call)

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

  shared_examples "a job that creates runs from score results" do |evaluation_class, run_class, association|
    let(:answer) { create(:answer) }
    let(:question) { answer.question }

    let(:results) do
      [
        build(:auto_evaluation_score_result, score: 0.8),
        build(:auto_evaluation_score_result, score: 0.7),
        build(:auto_evaluation_score_result, score: 0.9),
      ]
    end

    describe "#perform" do
      let(:answer_id) { answer.id }

      it "calls #{evaluation_class} the configured number of times with the correct arguments" do
        described_class.new.perform(answer_id)

        expect(evaluation_class)
          .to have_received(:call)
          .with(answer)
          .exactly(described_class::NUMBER_OF_RUNS).times
      end

      it "creates a #{association.to_s.singularize} for each result" do
        expect {
          described_class.new.perform(answer_id)
        }.to change(run_class, :count).by(results.count)

        answer = Answer.includes(association)
                       .find(answer_id)

        results.each_with_index do |result, index|
          expect(answer.public_send(association)[index])
            .to have_attributes(result.to_h.except(:success))
        end
      end

      context "when the answer does not exist" do
        let(:answer_id) { 999 }

        it "logs a warning" do
          expect(described_class.logger)
            .to receive(:warn)
            .with("Couldn't find an answer 999 that was eligible for auto-evaluation")

          described_class.new.perform(answer_id)
        end

        it "doesn't call #{evaluation_class}" do
          described_class.new.perform(answer_id)
          expect(evaluation_class).not_to have_received(:call)
        end
      end

      context "when #{association} are present on the answer" do
        let(:run) { create(association.to_s.singularize) }
        let(:answer) { run.answer }

        it "logs a warning" do
          expect(described_class.logger)
            .to receive(:warn)
            .with("Answer #{answer.id} has already been evaluated for #{described_class::EVALUATION_TYPE}")

          described_class.new.perform(answer.id)
        end

        it "doesn't call #{evaluation_class}" do
          described_class.new.perform(answer.id)
          expect(evaluation_class).not_to have_received(:call)
        end
      end

      context "when the answer is not eligible for auto-evaluation" do
        let(:answer) { create(:answer, status: Answer.statuses.except(:answered).keys.sample) }

        it "logs a warning message" do
          expect(described_class.logger)
            .to receive(:warn)
            .with("Couldn't find an answer #{answer.id} that was eligible for auto-evaluation")

          described_class.new.perform(answer.id)
        end

        it "does not call #{evaluation_class}" do
          expect(evaluation_class).not_to receive(:call)
          described_class.new.perform(answer.id)
        end
      end
    end
  end
end
