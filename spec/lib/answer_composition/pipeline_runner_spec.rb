RSpec.describe AnswerComposition::PipelineRunner do
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

    context "when the step raises an Anthropic::Errors::APIError" do
      let(:error) do
        Anthropic::Errors::APIError.new(
          url: "https://bedrock-runtime.eu-west-1.amazonaws.com/model/#{BedrockModels.model_id(:claude_sonnet_4_0)}:0/invoke",
        )
      end
      let(:pipeline_step) { ->(_context) { raise error } }

      it "notifies sentry" do
        expect(GovukError).to receive(:notify).with(kind_of(Anthropic::Errors::APIError))
        described_class.call(question:, pipeline: [pipeline_step])
      end

      it "returns the context's answer with the correct message, status and error_message" do
        result = described_class.call(question:, pipeline: [pipeline_step])

        expect(result)
          .to be_a(Answer)
          .and have_attributes(
            question:,
            status: "error_answer_service_error",
            message: Answer::CannedResponses::ANSWER_SERVICE_ERROR_RESPONSE,
            error_message: "Anthropic::Errors::APIError",
          )
      end
    end
  end
end
