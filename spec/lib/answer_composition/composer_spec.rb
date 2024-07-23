RSpec.describe AnswerComposition::Composer do
  let(:question) { create :question }
  let(:retrieved_answer) { build :answer, question: }

  describe ".call" do
    context "when the question is for open ai" do
      let(:question) { create :question, answer_strategy: :open_ai_rag_completion }

      it "calls OpenAIAnswer with the correct pipeline" do
        expected_pipeline = [
          AnswerComposition::Pipeline::QuestionRephraser,
          AnswerComposition::Pipeline::ForbiddenWordsChecker,
          AnswerComposition::Pipeline::SearchResultFetcher,
          AnswerComposition::Pipeline::OpenAIUnstructuredAnswerComposer,
          AnswerComposition::Pipeline::OutputGuardrails,
        ]
        expected_pipeline.each do |pipeline|
          allow(pipeline).to receive(:call) { |context| context }
        end
        expect(AnswerComposition::OpenAIAnswer).to receive(:call).and_call_original
        result = described_class.call(question)

        expect(result)
          .to be_an_instance_of(Answer)
          .and have_attributes(question:)
        expect(expected_pipeline).to all(have_received(:call))
      end
    end

    context "when the question is for chat API" do
      let(:question) { create :question, answer_strategy: :govuk_chat_api }

      it "get the result via ChatApiCompletion.call(question)" do
        allow(AnswerComposition::GovukChatApi)
          .to receive(:call).with(question).and_return(retrieved_answer)
        expect(described_class.call(question)).to eq(retrieved_answer)

        expect(AnswerComposition::GovukChatApi).to have_received(:call).with(question)
      end
    end

    context "when the question is for an unknown strategy" do
      let(:question) { build_stubbed(:question, answer_strategy: nil) }
      let(:result) { described_class.call(question) }

      it "builds an answer with the error_non_specific status" do
        expect(result.persisted?).to be false
        expect(result.status).to eq("error_non_specific")
      end

      it "sets the message to a generic failure message" do
        expect(result.message).to eq(Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE)
      end

      it "sets the error_message to the class of the error and the message" do
        expect(result.error_message).to eq("class: RuntimeError message: Answer strategy  not configured")
      end

      it "notifies sentry" do
        expect(GovukError).to receive(:notify).with(StandardError)
        result
      end
    end

    context "when an error is returned during answer generation" do
      let(:question) { create :question, answer_strategy: :open_ai_rag_completion }
      let(:result) { described_class.call(question) }

      before do
        allow(AnswerComposition::OpenAIAnswer)
        .to receive(:call)
        .and_raise(StandardError, "error message")
      end

      it "builds an answer with the error_non_specific status" do
        expect(result.persisted?).to be false
        expect(result.status).to eq("error_non_specific")
      end

      it "sets the message to a generic failure message" do
        expect(result.message).to eq(Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE)
      end

      it "sets the error_message to the class of the error and the message" do
        expect(result.error_message).to eq("class: StandardError message: error message")
      end

      it "notifies sentry" do
        expect(GovukError).to receive(:notify).with(StandardError)
        result
      end
    end
  end
end
