RSpec.describe "rake answer_analysis tasks" do
  describe "answer_analysis:backfill_request_types" do
    let(:task_name) { "answer_analysis:backfill_request_types" }
    let(:eligible_label) { Answer::QUESTION_ROUTING_LABELS_FOR_REQUEST_TYPE_ANALYSIS.sample }
    let(:status) { "success" }
    let(:error_message) { nil }
    let(:result) do
      AutoEvaluation::RequestTypeTagger::Result.new(
        status:,
        primary_request_type: "factual_lookup",
        secondary_request_type: "do_task",
        confidence: 0.9,
        reasoning: "The user is asking for a specific figure.",
        metrics: { "duration" => 1.5, "model" => "some-model" },
        llm_response: { "model" => "some-model" },
        error_message:,
      )
    end

    def create_eligible_answer(message: nil, **attributes)
      question = build(:question, message: message || "Message #{SecureRandom.uuid}")
      create(:answer, question:, question_routing_label: eligible_label, **attributes)
    end

    before do
      Rake::Task[task_name].reenable
      allow(AutoEvaluation::RequestTypeTagger).to receive(:call).and_return(result)
    end

    it "tags every eligible answer that doesn't have request types" do
      answers = Array.new(3) { create_eligible_answer }

      expect { Rake::Task[task_name].invoke }
        .to change(AnswerAnalysis::RequestTypes, :count).by(3)
        .and output.to_stdout

      answers.each do |answer|
        expect(answer.reload.request_types)
          .to have_attributes(
            status: result.status,
            primary_request_type: result.primary_request_type,
            secondary_request_type: result.secondary_request_type,
            confidence: result.confidence,
            reasoning: result.reasoning,
            metrics: { "request_type_tagger" => result.metrics },
            llm_responses: { "request_type_tagger" => result.llm_response },
            error_message: nil,
          )
      end
    end

    it "tags every answer exactly once when there are more of them than threads" do
      Array.new(25) { create_eligible_answer }

      expect { Rake::Task[task_name].invoke }
        .to change(AnswerAnalysis::RequestTypes, :count).by(25)
        .and output(a_string_including("Tagged 25 answers, 0 tagged with an error status, 0 failed"))
        .to_stdout
    end

    it "tags the answer with the question message" do
      create_eligible_answer(message: "How do I pay VAT?")

      expect { Rake::Task[task_name].invoke }.to output.to_stdout

      expect(AutoEvaluation::RequestTypeTagger).to have_received(:call).with("How do I pay VAT?")
    end

    it "tags the answer with the rephrased question when there is one" do
      create_eligible_answer(message: "How do I pay VAT?", rephrased_question: "What is the VAT rate?")

      expect { Rake::Task[task_name].invoke }.to output.to_stdout

      expect(AutoEvaluation::RequestTypeTagger).to have_received(:call).with("What is the VAT rate?")
    end

    it "doesn't tag answers that already have request types" do
      create(:answer, :with_request_types, question_routing_label: eligible_label)

      expect { Rake::Task[task_name].invoke }
        .to not_change(AnswerAnalysis::RequestTypes, :count)
        .and output.to_stdout

      expect(AutoEvaluation::RequestTypeTagger).not_to have_received(:call)
    end

    it "doesn't tag answers that aren't eligible for request type analysis" do
      ineligible_labels = Answer.question_routing_labels.keys -
        Answer::QUESTION_ROUTING_LABELS_FOR_REQUEST_TYPE_ANALYSIS
      create(:answer, question_routing_label: ineligible_labels.sample)

      expect { Rake::Task[task_name].invoke }
        .to not_change(AnswerAnalysis::RequestTypes, :count)
        .and output.to_stdout

      expect(AutoEvaluation::RequestTypeTagger).not_to have_received(:call)
    end

    it "outputs a summary of the outcomes" do
      create_eligible_answer

      expect { Rake::Task[task_name].invoke }
        .to output(a_string_including("Tagged 1 answer, 0 tagged with an error status, 0 failed"))
        .to_stdout
    end

    context "when the AutoEvaluation::RequestTypeTagger returns an error status" do
      let(:status) { "error" }
      let(:error_message) { "An error occurred during request type tagging" }

      it "creates request types with the error status and counts them separately" do
        answer = create_eligible_answer

        expect { Rake::Task[task_name].invoke }
          .to output(a_string_including("Tagged 0 answers, 1 tagged with an error status, 0 failed"))
          .to_stdout

        expect(answer.reload.request_types).to have_attributes(status:, error_message:)
      end
    end

    context "when tagging an answer raises an error" do
      let(:error) { Aws::BedrockRuntime::Errors::ThrottlingException.new({}, "Too many requests") }

      before do
        allow(AutoEvaluation::RequestTypeTagger).to receive(:call).with("Fails").and_raise(error)
        allow(AutoEvaluation::RequestTypeTagger).to receive(:call).with("Succeeds").and_return(result)
      end

      it "warns and carries on tagging the other answers" do
        create_eligible_answer(message: "Fails")
        succeeding_answer = create_eligible_answer(message: "Succeeds")

        expect { Rake::Task[task_name].invoke }
          .to change(AnswerAnalysis::RequestTypes, :count).by(1)
          .and output(a_string_including("Tagged 1 answer, 0 tagged with an error status, 1 failed")).to_stdout
          .and output(a_string_including("Aws::BedrockRuntime::Errors::ThrottlingException")).to_stderr

        expect(succeeding_answer.reload.request_types).to be_present
      end
    end

    it "doesn't raise when there are no answers to tag" do
      expect { Rake::Task[task_name].invoke }
        .to output(a_string_including("Backfilling request types for 0 answers")).to_stdout
    end
  end
end
