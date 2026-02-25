RSpec.describe AnswerComposition::Pipeline::Claude::QuestionRouter, :aws_credentials_stubbed do
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
    confidence_property = Rails.configuration.govuk_chat_private.llm_prompts.claude.question_routing[:confidence_property]

    [
      {
        name: "greetings",
        description: "A classification description",
        input_schema: {
          type: "object",
          properties: properties.merge({
            confidence: confidence_property,
          }),
          required: %w[confidence] + properties.keys.map(&:to_s),
          additionalProperties: false,
        },
        strict: true,
      },
    ]
  end

  let(:classification_response) do
    { "answer" => "Hello!", "confidence" => 0.85 }
  end

  let(:expected_message_history) do
    [
      { role: "user", content: question.message },
    ]
  end

  before do
    config = Rails.configuration.govuk_chat_private.llm_prompts.claude
    allow(config).to receive(:question_routing).and_return(
      classifications: [classification],
      system_prompt: "The system prompt",
      confidence_property: {
        title: "Confidence",
        type: "number",
        description: "The confidence that you have correctly identified the user's request",
      },
    )
  end

  describe ".call" do
    let(:question) { build :question }
    let(:context) { build(:answer_pipeline_context, question:) }

    it "calls Bedrock with with the right prompt and tool config" do
      request = stub_claude_question_routing(
        question.message,
        tools:,
        tool_name: "greetings",
        tool_input: classification_response,
      )

      described_class.call(context)
      expect(request).to have_been_made
    end

    it "assigns the llm response to the answer" do
      stub_claude_question_routing(
        question.message,
        tools:,
        tool_name: "greetings",
        tool_input: classification_response,
      )

      described_class.call(context)

      expected_content = claude_messages_tool_use_block(
        input: classification_response.symbolize_keys,
        name: "greetings",
      )
      expected_llm_response = claude_messages_response(
        content: [expected_content],
        usage: { cache_read_input_tokens: 20 },
        stop_reason: :tool_use,
      ).to_h
      expect(context.answer.llm_responses["question_routing"])
        .to match(expected_llm_response)
    end

    it "assigns metrics to the context's answer" do
      stub_claude_question_routing(
        question.message,
        tools:,
        tool_name: "greetings",
        tool_input: classification_response,
      )

      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(context)

      expect(context.answer.metrics["question_routing"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 30,
        llm_completion_tokens: 20,
        llm_cached_tokens: 20,
        model: BedrockModels.model_id(:claude_haiku),
      })
    end

    it "uses an overridden AWS region if set" do
      ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
        allow(Anthropic::BedrockClient).to receive(:new).and_call_original
        anthropic_request = stub_claude_question_routing(
          question.message,
          tools:,
          tool_name: "greetings",
          tool_input: classification_response,
        )

        described_class.call(context)

        expect(Anthropic::BedrockClient).to have_received(:new).with(hash_including(aws_region: "my-region"))
        expect(anthropic_request).to have_been_made
      end
    end

    context "when the question routing label is genuine_rag" do
      before do
        stub_claude_question_routing(
          question.message,
          tools:,
          tool_name: "genuine_rag",
          tool_input: classification_response,
        )
      end

      it "assigns the question routing label and confidence" do
        described_class.call(context)

        expect(context.answer).to have_attributes(
          question_routing_label: "genuine_rag",
          question_routing_confidence_score: 0.85,
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

    context "when the tokens returned by Bedrock exceeds the limit" do
      before do
        stub_claude_question_routing(
          question.message,
          tools:,
          tool_name: "vague_acronym_grammar",
          tool_input: classification_response,
          stop_reason: :max_tokens,
        )
      end

      it "assigns a canned response message" do
        canned_response = "Canned response"

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
        stub_claude_question_routing(
          question.message,
          tools:,
          tool_name: "multi_questions",
          tool_input: { "answer" => answer_message, "confidence" => 0.9 },
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
        stub_claude_question_routing(
          question.message,
          tools:,
          tool_name: "harmful_vulgar_controversy",
          tool_input: { "answer" => "Ignored", "confidence" => 0.9 },
        )
      end

      it "assigns a canned response message with a status and question routing metadata" do
        canned_response = "Canned response"

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
  end
end
