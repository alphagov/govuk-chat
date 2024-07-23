RSpec.describe AnswerComposition::OpenAIAnswer do # rubocop:disable RSpec/SpecFilePathFormat
  describe "#call" do
    let(:question) { build(:question) }

    it "returns the context's answer" do
      result = described_class.call(question:)

      expect(result)
        .to be_a(Answer)
        .and have_attributes(question:)
    end

    it "iterates through the pipeline steps and calls #call for each step" do
      pipeline_step_1 = ->(_context) { nil }
      pipeline_step_2 = ->(_context) { nil }
      expect(pipeline_step_1).to receive(:call).with(an_instance_of(AnswerComposition::Pipeline::Context))
      expect(pipeline_step_2).to receive(:call).with(an_instance_of(AnswerComposition::Pipeline::Context))

      described_class.call(question:, pipeline: [pipeline_step_1, pipeline_step_2])
    end

    context "when a step throws an :abort symbol" do
      it "aborts the pipeline and returns the context's answer" do
        pipeline_step_1 = ->(context) { context.abort_pipeline! }
        pipeline_step_2 = ->(_context) { nil }
        expect(pipeline_step_2).not_to receive(:call)

        result = described_class.call(question:, pipeline: [pipeline_step_1, pipeline_step_2])

        expect(result)
          .to be_a(Answer)
          .and have_attributes(question:)
      end
    end

    context "when a step sets the context's aborted attribute to true" do
      it "aborts the pipeline and returns the context's answer" do
        pipeline_step_1 = ->(context) { context.abort_pipeline }
        pipeline_step_2 = ->(_context) { nil }
        expect(pipeline_step_2).not_to receive(:call)

        result = described_class.call(question:, pipeline: [pipeline_step_1, pipeline_step_2])

        expect(result)
          .to be_a(Answer)
          .and have_attributes(question:)
      end
    end

    context "when the step raises an OpenAIClient::ContextLengthExceededError" do
      let(:error) { OpenAIClient::ContextLengthExceededError.new("error message") }
      let(:pipeline_step) { ->(_context) { raise error } }

      it "notifies sentry" do
        expect(GovukError).to receive(:notify).with(error)
        described_class.call(question:, pipeline: [pipeline_step])
      end

      it "returns the context's answer with the correct message, status and error_message" do
        result = described_class.call(question:, pipeline: [pipeline_step])
        expect(result)
          .to be_a(Answer)
          .and have_attributes(
            question:,
            status: "error_context_length_exceeded",
            message: Answer::CannedResponses::CONTEXT_LENGTH_EXCEEDED_RESPONSE,
            error_message: "class: OpenAIClient::ContextLengthExceededError message: error message",
          )
      end
    end

    context "when the step raises an OpenAIClient::RequestError" do
      let(:error) { OpenAIClient::RequestError.new("error message") }
      let(:pipeline_step) { ->(_context) { raise error } }

      it "notifies sentry" do
        expect(GovukError).to receive(:notify).with(error)
        described_class.call(question:, pipeline: [pipeline_step])
      end

      it "returns the context's answer with the correct message, status and error_message" do
        result = described_class.call(question:, pipeline: [pipeline_step])

        expect(result)
          .to be_a(Answer)
          .and have_attributes(
            question:,
            status: "error_answer_service_error",
            message: Answer::CannedResponses::OPENAI_CLIENT_ERROR_RESPONSE,
            error_message: "class: OpenAIClient::RequestError message: error message",
          )
      end
    end
  end
end
