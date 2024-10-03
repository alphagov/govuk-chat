RSpec.describe AnswerComposition::Pipeline::QuestionRouter do
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

    [{
      type: "function",
      function: {
        name: "greetings",
        description: "A classification description",
        strict: true,
        parameters: {
          type: "object",
          properties: classification[:properties].merge({
            confidence: llm_prompts[:confidence_property],
          }),
          required: (classification[:properties].keys + %i[confidence]).map(&:to_s),
          additionalProperties: false,
        },
      },

    }]
  end

  let(:expected_message_history) do
    [
      { role: "system", content: llm_prompts[:system_prompt] },
      { role: "user", content: question.message },
    ]
  end

  before do
    allow(Rails.configuration.llm_prompts.question_routing).to receive(:[]).and_call_original
    allow(Rails.configuration.llm_prompts.question_routing)
    .to receive(:[]).with(:classifications).and_return([classification])
  end

  describe ".call" do
    let(:question) { build :question }
    let(:context) { build(:answer_pipeline_context, question:) }

    it "sends OpenAI a series of messages combining system prompt and the user question" do
      request = stub_openai_chat_question_routing(expected_message_history, tools:)

      described_class.call(context)

      expect(request).to have_been_made
    end

    it "assigns the llm response to the answer" do
      stub_openai_chat_question_routing(expected_message_history, tools:)

      described_class.call(context)

      expect(context.answer.llm_responses["question_routing"]).to match(
        hash_including_openai_response_with_tool_call("genuine_rag"),
      )
    end

    context "when a successful response is received" do
      it "assigns the correct values to the context's answer when genuine_rag" do
        stub_openai_chat_question_routing(expected_message_history, tools:)

        described_class.call(context)

        expect(context.answer).to have_attributes(
          question_routing_label: "genuine_rag",
          question_routing_confidence_score: nil,
        )
      end

      it "assigns metrics to the answer" do
        stub_openai_chat_question_routing(expected_message_history, tools:)
        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)

        described_class.call(context)

        expect(context.answer.metrics["question_routing"]).to eq({
          duration: 1.5,
          llm_prompt_tokens: 13,
          llm_completion_tokens: 7,
        })
      end

      it "aborts the pipeline and assigns the correct values to the context's answer when not genuine_rag" do
        classification_response = {
          answer: "Hello!",
          confidence: 0.85,
        }

        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "greetings",
          function_arguments: classification_response,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)

        expect(context.answer).to have_attributes(
          status: "abort_question_routing",
          question_routing_label: "greetings",
          message: "Hello! How can I help you today?",
          question_routing_confidence_score: 0.85,
          metrics: a_hash_including("question_routing" => {
            duration: 1.5,
            llm_prompt_tokens: 13,
            llm_completion_tokens: 7,
          }),
        )
      end

      it "raises an error if the label is invalid" do
        classification_response = {
          answer: "Hello!",
          confidence: 0.85,
        }

        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "invalid_label",
          function_arguments: classification_response,
        )

        expect { described_class.call(context) }.to raise_error(
          AnswerComposition::Pipeline::QuestionRouter::InvalidLabelError,
          "Invalid label: invalid_label",
        )
      end
    end

    context "when the classification has additional properties" do
      let(:classification) do
        classification_attributes.merge(
          properties: {
            answer: {
              type: "string",
              description: "Answer the question.",
            },
            main_topic: {
              type: "string",
              description: "The main topic or primary focus of the user request.",
            },
          },
          required: %w[answer main_topic],
        )
      end

      it "makes a successful request to OpenAI and aborts the pipeline" do
        classification_response = {
          answer: "Hi there",
          confidence: 0.9,
          main_topic: "This is the main topic",
        }

        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "greetings",
          function_arguments: classification_response,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)
        expect(context.answer).to have_attributes(
          status: "abort_question_routing",
          question_routing_label: "greetings",
          message: "Hi there",
          question_routing_confidence_score: 0.9,
          metrics: a_hash_including("question_routing" => {
            duration: 1.5,
            llm_prompt_tokens: 13,
            llm_completion_tokens: 7,
          }),
        )
      end

      it "aborts the pipeline if the schema is invalid" do
        # This schema doesn't have the main_topic property, which is required
        classification_response = {
          answer: "Hello!",
          confidence: 0.85,
        }

        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "greetings",
          function_arguments: classification_response,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)
          .and change { context.answer.status }.to("error_question_routing")
      end
    end

    context "when OpenAI passes JSON back that is invalid against the Output schema" do
      it "aborts the pipeline" do
        classification_response = { something: "irrelevant" }

        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "greetings",
          function_arguments: classification_response,
        )

        expect(context).to receive(:abort_pipeline!).with(
          status: "error_question_routing",
          message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
          error_message: "class: JSON::Schema::ValidationError message: The property '#/' did not contain a required property of 'answer'",
          metrics: a_hash_including("question_routing" => {
            duration: 1.5,
            llm_prompt_tokens: 13,
            llm_completion_tokens: 7,
          }),
        )

        described_class.call(context)
      end
    end

    context "when OpenAI passes invalid JSON in the response" do
      it "aborts the pipeline" do
        classification_response = "this will blow up"

        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "greetings",
          function_arguments: classification_response,
        )

        expect(context).to receive(:abort_pipeline!).with(
          status: "error_question_routing",
          message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
          error_message: "class: JSON::ParserError message: unexpected token at 'this will blow up'",
          metrics: a_hash_including("question_routing" => {
            duration: 1.5,
            llm_prompt_tokens: 13,
            llm_completion_tokens: 7,
          }),
        )

        described_class.call(context)
      end
    end

    def llm_prompts
      Rails.configuration.llm_prompts.question_routing
    end
  end
end
