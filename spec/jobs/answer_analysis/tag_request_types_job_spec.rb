RSpec.describe AnswerAnalysis::TagRequestTypesJob do
  include ActiveJob::TestHelper
  let(:eligible_question_routing_label) { Answer::QUESTION_ROUTING_LABELS_FOR_REQUEST_TYPE_ANALYSIS.sample }
  let(:answer) { create(:answer, question_routing_label: eligible_question_routing_label) }
  let(:question) { answer.question }
  let(:request_type_tagger_result) do
    AutoEvaluation::RequestTypeTagger::Result.new(
      status: status,
      primary_request_type: "factual_lookup",
      secondary_request_type: "do_task",
      confidence: 0.9,
      reasoning: "The user is asking for a specific figure.",
      metrics: {
        "duration" => 1.5,
        "model" => "some-model",
      },
      llm_response: {
        "model" => "some-model",
      },
      error_message:,
    )
  end
  let(:status) { "success" }
  let(:error_message) { nil }

  before do
    allow(AutoEvaluation::RequestTypeTagger).to receive(:call).and_return(request_type_tagger_result)
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  it_behaves_like "a job in queue", "default"
  it_behaves_like "a job that adheres to the auto_evaluation quota",
                  AutoEvaluation::RequestTypeTagger,
                  { question_routing_label: :genuine_rag }
  it_behaves_like "a job that retries on aws sdk errors",
                  AutoEvaluation::RequestTypeTagger,
                  { question_routing_label: :genuine_rag }

  describe "#perform" do
    it "calls the AutoEvaluation::RequestTypeTagger with the answer message" do
      described_class.new.perform(answer.id)
      expect(AutoEvaluation::RequestTypeTagger).to have_received(:call).with(question.message)
    end

    it "creates request types for the answer based of the returned result" do
      expect {
        described_class.new.perform(answer.id)
      }.to change(AnswerAnalysis::RequestTypes, :count).by(1)
      expect(answer.reload.request_types)
        .to have_attributes(
          status: request_type_tagger_result.status,
          primary_request_type: request_type_tagger_result.primary_request_type,
          secondary_request_type: request_type_tagger_result.secondary_request_type,
          confidence: request_type_tagger_result.confidence,
          reasoning: request_type_tagger_result.reasoning,
          metrics: { "request_type_tagger" => request_type_tagger_result.metrics },
          llm_responses: { "request_type_tagger" => request_type_tagger_result.llm_response },
          error_message: nil,
        )
    end

    context "when the AutoEvaluation::RequestTypeTagger returns an error status and error message" do
      let(:status) { "error" }
      let(:error_message) { "An error occurred during request type tagging" }

      it "creates request types with the error status and error message" do
        described_class.new.perform(answer.id)
        expect(answer.reload.request_types)
          .to have_attributes(
            status: status,
            error_message: error_message,
          )
      end
    end

    context "when the answer does not exist" do
      let(:answer_id) { 999 }

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("No answer found for #{answer_id}")

        described_class.new.perform(answer_id)
      end

      it "doesn't call the AutoEvaluation::RequestTypeTagger" do
        described_class.new.perform(answer_id)
        expect(AutoEvaluation::RequestTypeTagger).not_to have_received(:call)
      end
    end

    context "when request types have been tagged" do
      let(:answer) do
        create(:answer, :with_request_types, question_routing_label: eligible_question_routing_label)
      end

      it "logs a warning" do
        expect(described_class.logger)
          .to receive(:warn)
          .with("Answer #{answer.id} has already been tagged with request types")

        described_class.new.perform(answer.id)
      end
    end

    context "when the answer is not eligible for request type analysis" do
      let(:ineligible_question_routing_labels) do
        Answer.question_routing_labels.keys - Answer::QUESTION_ROUTING_LABELS_FOR_REQUEST_TYPE_ANALYSIS
      end
      let(:answer) { create(:answer, question_routing_label: ineligible_question_routing_labels.sample) }

      it "logs an info message" do
        expect(described_class.logger)
          .to receive(:info)
          .with("Answer #{answer.id} is not eligible for request type analysis")

        described_class.new.perform(answer.id)
      end

      it "does not call the AutoEvaluation::RequestTypeTagger" do
        expect(AutoEvaluation::RequestTypeTagger).not_to receive(:call)
        described_class.new.perform(answer.id)
      end
    end
  end
end
