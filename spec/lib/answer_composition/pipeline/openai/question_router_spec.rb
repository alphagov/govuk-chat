RSpec.describe AnswerComposition::Pipeline::OpenAI::QuestionRouter do # rubocop:disable RSpec/SpecFilePathFormat
  let(:classification_attributes) do
    {
      name: "greetings",
      description: "A classification description",
      properties: {
        answer: {
          type: "string",
          description: "Answer the question.",
        },
      },
      required: %w[answer],
    }
  end
  let(:classification) do
    classification_attributes
  end

  let(:tools) do
    properties = classification[:properties] || {}

    [{
      type: "function",
      function: {
        name: "greetings",
        description: "A classification description",
        strict: true,
        parameters: {
          type: "object",
          properties: properties.merge({
            confidence: llm_prompts[:confidence_property],
          }),
          required: %w[confidence] + properties.keys.map(&:to_s),
          additionalProperties: false,
        },
      },
    }]
  end

  let(:classification_response) do
    { answer: "Hello!", confidence: 0.85 }.to_json
  end

  let(:expected_message_history) do
    [
      { role: "system", content: "The system prompt" },
      { role: "user", content: question.message },
    ]
  end

  before do
    config = Rails.configuration.govuk_chat_private.llm_prompts.openai
    allow(config).to receive(:question_routing).and_return(
      classifications: [classification],
      system_prompt: "The system prompt",
    )
  end

  describe ".call" do
    let(:question) { build :question }
    let(:context) { build(:answer_pipeline_context, question:) }

    it "sends OpenAI a series of messages combining system prompt and the user question" do
      request = stub_openai_chat_question_routing(
        expected_message_history,
        tools:,
        function_name: "greetings",
        function_arguments: classification_response,
      )

      described_class.call(context)

      expect(request).to have_been_made
    end

    it "assigns the llm response to the answer" do
      stub_openai_chat_question_routing(
        expected_message_history,
        tools:,
        function_name: "greetings",
        function_arguments: classification_response,
      )

      described_class.call(context)

      expect(context.answer.llm_responses["question_routing"]).to match(
        hash_including_openai_response_with_tool_call("greetings"),
      )
    end

    it "assigns metrics to the context's answer" do
      stub_openai_chat_question_routing(
        expected_message_history,
        tools:,
        function_name: "greetings",
        function_arguments: classification_response,
      )
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(context)

      expect(context.answer.metrics["question_routing"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
        llm_cached_tokens: 10,
      })
    end

    context "when the question routing label is genuine_rag" do
      before do
        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "genuine_rag",
          function_arguments: { answer: "Generic answer", confidence: 0.9 }.to_json,
        )
      end

      it "assigns the question routing label and confidence" do
        described_class.call(context)

        expect(context.answer).to have_attributes(
          question_routing_label: "genuine_rag",
          question_routing_confidence_score: 0.9,
        )
      end

      it "doesn't assign a message" do
        described_class.call(context)

        expect(context.answer.message).to be_nil
      end

      it "doesn't abort the pipeline" do
        expect { described_class.call(context) }
          .not_to change(context, :aborted?).from(false)
      end
    end

    context "when the tokens returned by OpenAI exceeds the limit" do
      before do
        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "vague_acronym_grammar",
          function_arguments: '{"answer": "A long answer that is terminated mid senten',
          finish_reason: "length",
        )
      end

      it "assigns a canned response message" do
        canned_response = "Canned response"

        # This method returns a random value
        allow(Answer::CannedResponses)
          .to receive(:response_for_question_routing_label)
          .with("vague_acronym_grammar")
          .and_return(canned_response)

        described_class.call(context)

        expect(context.answer).to have_attributes(
          message: canned_response,
          status: "clarification",
          question_routing_label: "vague_acronym_grammar",
        )
      end

      it "aborts the pipeline" do
        expect { described_class.call(context) }
          .to change(context, :aborted?).to(true)
      end
    end

    context "when the question routing label is one where we use the answer" do
      let(:answer_message) { "This content was not found on GOV.UK" }

      before do
        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "multi_questions",
          function_arguments: { answer: answer_message, confidence: 0.9 }.to_json,
        )
      end

      it "assigns the answer message, status and question routing metadata" do
        described_class.call(context)

        expect(context.answer).to have_attributes(
          message: answer_message,
          status: "clarification",
          question_routing_label: "multi_questions",
          question_routing_confidence_score: 0.9,
        )
      end

      it "doesn't abort the pipeline" do
        expect { described_class.call(context) }
          .not_to change(context, :aborted?).from(false)
      end
    end

    context "when the question routing label is one where we ignore the answer" do
      before do
        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "harmful_vulgar_controversy",
          function_arguments: { answer: "Ignored", confidence: 0.9 }.to_json,
        )
      end

      it "assigns a canned response message with a status and question routing metadata" do
        canned_response = "Canned response"

        # This method returns a random value
        allow(Answer::CannedResponses)
          .to receive(:response_for_question_routing_label)
          .with("harmful_vulgar_controversy")
          .and_return(canned_response)

        described_class.call(context)

        expect(context.answer).to have_attributes(
          message: canned_response,
          status: "unanswerable_question_routing",
          question_routing_label: "harmful_vulgar_controversy",
          question_routing_confidence_score: 0.9,
        )
      end

      it "aborts the pipeline" do
        expect { described_class.call(context) }
          .to change(context, :aborted?).to(true)
      end
    end

    def llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.openai.question_routing
    end
  end
end
