RSpec.describe AnswerComposition::Composer do
  let(:question) { create :question }
  let(:retrieved_answer) { build :answer, question: }

  describe ".call" do
    context "when the question is for open ai" do
      context "and the answer strategy is 'openai_structured_answer'" do
        let(:question) { create :question, answer_strategy: :openai_structured_answer }

        it "calls OpenAIAnswer with the correct pipeline" do
          expected_pipeline = [
            AnswerComposition::Pipeline::JailbreakGuardrails,
            AnswerComposition::Pipeline::QuestionRephraser,
            AnswerComposition::Pipeline::QuestionRouter,
            AnswerComposition::Pipeline::QuestionRoutingGuardrails,
            AnswerComposition::Pipeline::SearchResultFetcher,
            AnswerComposition::Pipeline::OpenAIStructuredAnswerComposer,
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
      let(:question) { create :question, answer_strategy: :openai_structured_answer }
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

      it "assigns metrics to the answer" do
        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)

        expect(result.metrics["answer_composition"]).to match({
          "duration" => 1.5,
        })
      end
    end

    context "when there are forbidden terms in the answer message" do
      let(:answer) { build(:answer, message: "message with badword") }

      before do
        allow(Rails.configuration).to receive(:forbidden_terms).and_return(Set.new(%w[badword]))
        allow(AnswerComposition::OpenAIAnswer).to receive(:call).and_return(answer)
      end

      it "returns an answer with FORBIDDEN_TERMS_MESSAGE" do
        result = described_class.call(question)

        expect(result)
          .to be_an_instance_of(Answer)
          .and have_attributes(
            message: Answer::CannedResponses::FORBIDDEN_TERMS_MESSAGE,
            status: "abort_forbidden_terms",
          )
      end
    end
  end

  it "assigns metrics to the answer" do
    answer = create(:answer)
    allow(AnswerComposition::OpenAIAnswer).to receive(:call).and_return(answer)
    allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)

    described_class.call(answer.question)
    expect(answer.metrics["answer_composition"]).to match({
      duration: 1.5,
    })
  end
end
