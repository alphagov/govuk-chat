RSpec.describe AnswerComposition::MultipleGuardrail::Checker, :aws_credentials_stubbed do
  let(:input) { "This is a test input." }
  let(:formatted_date) { Date.current.strftime("%A %d %B %Y") }
  let(:prompt) { instance_double(AnswerComposition::MultipleGuardrail::Prompt) }
  let(:llm_prompt_name) { :answer_guardrails }

  it_behaves_like "a claude answer composition component with a configurable model", "BEDROCK_CLAUDE_GUARDRAILS_MODEL" do
    let(:pipeline_step) { described_class.new(input, llm_prompt_name) }
    let(:stubbed_request_lambda) do
      lambda { |bedrock_model|
        stub_claude_output_guardrails(
          input,
          [1, 2].to_json,
          chat_options: { bedrock_model: },
        )
      }
    end
  end

  describe ".call" do
    let(:model) { described_class::DEFAULT_MODEL }
    let(:input) { "This is a test input." }
    let(:guardrails_config) do
      {
        system_prompt: "{guardrails} {date}",
        user_prompt: "{input}",
        guardrails:,
        guardrail_definitions:,
      }.with_indifferent_access
    end
    let(:guardrails) { %w[political appropriate_language] }
    let(:guardrail_definitions) do
      {
        "political" => "This is a political guardrail",
        "appropriate_language" => "This is an appropriate language guardrail",
      }
    end
    let(:guardrail_objects) do
      guardrails.map.with_index(1) do |name, key|
        AnswerComposition::MultipleGuardrail::Prompt::Guardrail.new(
          key: key,
          name: name,
          content: guardrail_definitions[name],
        )
      end
    end
    let(:llm_guardrail_result) { [1, 2].to_json }
    let(:stub) do
      stub_claude_output_guardrails(
        input,
        llm_guardrail_result,
        chat_options: { bedrock_model: model },
      )
    end
    let(:system_prompt) do
      "Structured system prompt: 1. This is a political guardrail\n2. This is an appropriate language guardrail #{formatted_date}"
    end

    before do
      allow(AnswerComposition::Pipeline::Prompts).to receive(:config)
                                                 .with(llm_prompt_name, model)
                                                 .and_return(guardrails_config)

      allow(prompt).to receive_messages(
        system_prompt: system_prompt,
        guardrails: guardrail_objects,
      )
      allow(prompt).to receive(:user_prompt).with(input).and_return(input)
      stub_const("#{described_class}::DEFAULT_MODEL", model)
      stub
    end

    it "uses an overridden AWS region if set" do
      ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
        allow(Anthropic::BedrockClient).to receive(:new).and_call_original

        described_class.call(input, llm_prompt_name)

        expect(Anthropic::BedrockClient).to have_received(:new).with(hash_including(aws_region: "my-region"))
        expect(stub).to have_been_requested
      end
    end

    it "calls Claude to check for guardrail violations with correct user input" do
      described_class.call(input, llm_prompt_name)
      expect(stub).to have_been_requested
    end

    it "returns a true result with matched guardrails" do
      result = described_class.call(input, llm_prompt_name)
      expect(result).to have_attributes(
        llm_guardrail_result: JSON.parse(llm_guardrail_result).to_s,
        guardrails: { political: true, appropriate_language: true },
        triggered: true,
      )
    end

    it "returns a false result with no matched guardrails" do
      stub_claude_output_guardrails(
        input,
        [].to_json,
        chat_options: { bedrock_model: model },
      )

      result = described_class.call(input, llm_prompt_name)

      expect(result).to have_attributes(
        llm_guardrail_result: "[]",
        guardrails: { political: false, appropriate_language: false },
        triggered: false,
      )
    end

    it "returns the LLM token usage" do
      result = described_class.call(input, llm_prompt_name)

      expect(result).to have_attributes(
        llm_prompt_tokens: 10,
        llm_completion_tokens: 20,
        llm_cached_tokens: 20,
      )
    end

    it "returns the llm response" do
      result = described_class.call(input, llm_prompt_name)

      expected_llm_response = claude_messages_response(
        content: [claude_messages_text_block(llm_guardrail_result)],
        usage: { cache_read_input_tokens: 20 },
        bedrock_model: model,
      ).to_h
      expect(result.llm_response).to eq(expected_llm_response)
    end

    it "returns the model used" do
      result = described_class.call(input, llm_prompt_name)
      expect(result.model).to eq(BedrockModels.model_id(model))
    end

    context "when the guardrail type is :question_routing_guardrails" do
      let(:llm_prompt_name) { :question_routing_guardrails }

      it "calls Claude using the question routing guardrails" do
        described_class.call(input, llm_prompt_name)

        expect(stub).to have_been_requested
        expect(AnswerComposition::Pipeline::Prompts)
          .to have_received(:config).with(llm_prompt_name, model).at_least(:once)
        expect(AnswerComposition::Pipeline::Prompts)
          .not_to have_received(:config).with(:answer_guardrails, model)
      end
    end
  end
end
