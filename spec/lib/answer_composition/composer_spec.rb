RSpec.describe AnswerComposition::Composer do
  let(:question) { create :question }
  let(:retrieved_answer) { build :answer, question: }

  describe ".call" do
    it "assigns metrics to the answer" do
      answer = create(:answer)
      allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(answer.question)
      expect(answer.metrics["answer_composition"]).to match({
        duration: 1.5,
      })
    end

    context "when the user associated with the question has been shadow banned" do
      it "returns an answer with the correct attributes" do
        user = create(:early_access_user, :shadow_banned)
        conversation = create(:conversation, user:)
        question = create(:question, conversation:)

        result = described_class.call(question)

        expect(result)
          .to be_an_instance_of(Answer)
          .and have_attributes(
            question:,
            message: Answer::CannedResponses::SHADOW_BANNED_MESSAGE,
            status: "banned",
          )
      end
    end

    context "when the question is for the 'openai_structured_answer' strategy" do
      let(:question) { create :question, answer_strategy: :openai_structured_answer }

      it "calls PipelineRunner with the correct pipeline" do
        rephraser = instance_double(AnswerComposition::Pipeline::QuestionRephraser)
        allow(AnswerComposition::Pipeline::QuestionRephraser)
          .to receive(:new).with(llm_provider: :openai).and_return(rephraser)

        question_routing_guardrails = instance_double(AnswerComposition::Pipeline::QuestionRoutingGuardrails)
        allow(AnswerComposition::Pipeline::QuestionRoutingGuardrails)
          .to receive(:new).with(llm_provider: :openai).and_return(question_routing_guardrails)

        answer_guardrails = instance_double(AnswerComposition::Pipeline::AnswerGuardrails)
        allow(AnswerComposition::Pipeline::AnswerGuardrails)
          .to receive(:new).with(llm_provider: :openai).and_return(answer_guardrails)

        expected_pipeline = [
          AnswerComposition::Pipeline::JailbreakGuardrails,
          AnswerComposition::Pipeline::QuestionRephraser.new(llm_provider: :openai),
          AnswerComposition::Pipeline::OpenAI::QuestionRouter,
          AnswerComposition::Pipeline::QuestionRoutingGuardrails.new(llm_provider: :openai),
          AnswerComposition::Pipeline::SearchResultFetcher,
          AnswerComposition::Pipeline::OpenAI::StructuredAnswerComposer,
          AnswerComposition::Pipeline::AnswerGuardrails.new(llm_provider: :openai),
        ]
        expected_pipeline.each do |pipeline|
          allow(pipeline).to receive(:call) { |context| context }
        end
        expect(AnswerComposition::PipelineRunner).to receive(:call).and_call_original
        result = described_class.call(question)

        expect(result)
          .to be_an_instance_of(Answer)
          .and have_attributes(question:)
        expect(expected_pipeline).to all(have_received(:call))
      end
    end

    context "when the question is for the 'claude_structured_answer' strategy" do
      let(:question) { create :question, answer_strategy: :claude_structured_answer }

      it "calls PipelineRunner with the correct pipeline" do
        rephraser = instance_double(AnswerComposition::Pipeline::QuestionRephraser)
        allow(AnswerComposition::Pipeline::QuestionRephraser)
          .to receive(:new).with(llm_provider: :claude).and_return(rephraser)
        search_result_fetcher = instance_double(AnswerComposition::Pipeline::SearchResultFetcher)
        allow(AnswerComposition::Pipeline::SearchResultFetcher)
          .to receive(:new).with(llm_provider: :claude).and_return(search_result_fetcher)

        expected_pipeline = [
          AnswerComposition::Pipeline::QuestionRephraser.new(llm_provider: :claude),
          AnswerComposition::Pipeline::Claude::QuestionRouter,
          AnswerComposition::Pipeline::SearchResultFetcher,
          AnswerComposition::Pipeline::Claude::StructuredAnswerComposer,
        ]
        expected_pipeline.each do |pipeline|
          allow(pipeline).to receive(:call) { it }
        end
        expect(AnswerComposition::PipelineRunner).to receive(:call).and_call_original
        result = described_class.call(question)

        expect(result)
          .to be_an_instance_of(Answer)
          .and have_attributes(question:)
        expect(expected_pipeline).to all(have_received(:call))
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
        allow(AnswerComposition::PipelineRunner)
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
        allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

        expect(result.metrics["answer_composition"]).to match({
          duration: 1.5,
        })
      end

      it "preserves the existing answer" do
        question.build_answer(llm_responses: { "question_routing" => "something" })
        expect(result.llm_responses).to eq("question_routing" => "something")
      end

      it "sets the answer sources to unused" do
        answer = question.build_answer
        build(:answer_source, answer:, used: true)
        build(:answer_source, answer:, used: false)

        result

        expect(answer.sources.map(&:used?)).to all(be_true)
      end
    end

    context "when there are forbidden terms in the answer message" do
      let(:answer) { build(:answer, message: "message with badword") }

      before do
        allow(Rails.configuration.govuk_chat_private).to receive(:forbidden_terms).and_return(Set.new(%w[badword]))
        allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)
      end

      it "returns an answer with FORBIDDEN_TERMS_MESSAGE" do
        result = described_class.call(question)

        expect(result)
          .to be_an_instance_of(Answer)
          .and have_attributes(
            message: Answer::CannedResponses::FORBIDDEN_TERMS_MESSAGE,
            status: "guardrails_forbidden_terms",
          )
      end
    end
  end
end
