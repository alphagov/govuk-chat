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
    { answer: "Hello!", confidence: 0.85 }
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

    it "assigns the correct values to the context's answer" do
      stub_openai_chat_question_routing(
        expected_message_history,
        tools:,
        function_name: "greetings",
        function_arguments: classification_response,
      )

      described_class.call(context)

      expect(context.answer).to have_attributes(
        question_routing_label: "greetings",
        question_routing_confidence_score: 0.85,
        message: "Hello! How can I help you today?",
      )
    end

    it "assigns metrics to the context's answer" do
      stub_openai_chat_question_routing(
        expected_message_history,
        tools:,
        function_name: "greetings",
        function_arguments: classification_response,
      )
      allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(context)

      expect(context.answer.metrics["question_routing"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
      })
    end

    context "when the LLM response does not contain an answer" do
      let(:classification_attributes) do
        {
          name: "greetings",
          description: "A classification description",
          
          
        }
      end

      it "assigns a canned response as the message" do
        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "greetings",
          function_arguments: { confidence: 0.85 },
        )
        allow(Answer::CannedResponses)
          .to receive(:response_for_question_routing_label).with("greetings")
          .and_return("Canned response")

        described_class.call(context)

        expect(context.answer).to have_attributes(message: "Canned response")
      end

      it "aborts the pipeline" do
        expect(context).to receive(:abort_pipeline)

        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "greetings",
          function_arguments: { confidence: 0.85 },
        )

        described_class.call(context)
      end
    end

    it "raises an error if the label is invalid" do
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

    context "when the response isn't genuine_rag" do
      let(:classification_attributes) do
        {
          name: "greetings",
          description: "A classification description",
          
          
        }
      end

      it "makes a successful request to OpenAI and sets the attributes" do
        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
        allow(Answer::CannedResponses)
          .to receive(:response_for_question_routing_label).with("greetings")
          .and_return("Canned response")

        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "greetings",
          function_arguments: { confidence: 0.9 },
        )

        described_class.call(context)

        expect(context.answer).to have_attributes(
          status: "abort_question_routing",
          question_routing_label: "greetings",
          message: "Canned response",
          question_routing_confidence_score: 0.9,
          metrics: a_hash_including("question_routing" => {
            duration: 1.5,
            llm_prompt_tokens: 13,
            llm_completion_tokens: 7,
          }),
        )
      end

      it "aborts the pipeline" do
        expect(context).to receive(:abort_pipeline)

        stub_openai_chat_question_routing(
          expected_message_history,
          tools:,
          function_name: "greetings",
          function_arguments: { confidence: 0.85 },
        )

        described_class.call(context)
      end
    end

    context "when schema validation fails" do
      it "aborts the pipeline when OpenAI passes JSON back that is invalid against the Output schema" do
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
          error_message: a_string_including("class: JSON::Schema::ValidationError"),
          metrics: a_hash_including("question_routing" => {
            duration: 1.5,
            llm_prompt_tokens: 13,
            llm_completion_tokens: 7,
          }),
        )

        described_class.call(context)
      end

      it "aborts the pipeline when OpenAI passes invalid JSON in the response" do
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
