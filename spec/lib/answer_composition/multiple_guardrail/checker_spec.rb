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
          'True | "1, 2"',
          chat_options: { bedrock_model: },
        )
      }
    end
  end

  describe ".call" do
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

    let!(:stub) { stub_claude_output_guardrails(input) }

    before do
      allow(AnswerComposition::Pipeline::Prompts).to receive(:config)
                                                 .with(llm_prompt_name, described_class::DEFAULT_MODEL)
                                                 .and_return(guardrails_config)
    end

    it "uses an overridden AWS region if set" do
      ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
        allow(Anthropic::BedrockClient).to receive(:new).and_call_original

        described_class.call(input, llm_prompt_name)

        expect(Anthropic::BedrockClient).to have_received(:new).with(hash_including(aws_region: "my-region"))
        expect(stub).to have_been_requested
      end
    end

    context "when the request is successful" do
      let(:llm_prompt_name) { :answer_guardrails }
      let(:guardrails_config) { Rails.configuration.govuk_chat_private.llm_prompts.claude }
      let(:guardrail_definitions) do
        {
          "costs" => "This is a costs guardrail",
          "personal" => "This is a personal guardrail",
          "unique_answer_guardrail" => "This is a unique answer guardrail",
        }
      end
      let(:guardrails) { %w[costs personal unique_answer_guardrail] }
      let!(:stub) { stub_claude_output_guardrails(input, 'True | "1, 2"') }

      before do
        allow(Rails.logger).to receive(:error)
        allow(AnswerComposition::MultipleGuardrail::Prompt).to receive(:new).with(llm_prompt_name).and_return(prompt)

        guardrail_objects = guardrails.map.with_index(1) do |name, key|
          AnswerComposition::MultipleGuardrail::Prompt::Guardrail.new(
            key: key,
            name: name,
            content: guardrail_definitions[name],
          )
        end

        allow(prompt).to receive_messages(
          system_prompt: "1. This is a costs guardrail\n2. This is a personal guardrail\n3. This is a unique answer guardrail #{formatted_date}",
          guardrails: guardrail_objects,
        )

        allow(prompt).to receive(:user_prompt).with(input).and_return(input)
      end

      it "calls Claude to check for guardrail violations with correct user input" do
        described_class.call(input, llm_prompt_name)
        expect(stub).to have_been_requested
      end

      it "returns a true result with matched guardrails" do
        result = described_class.call(input, llm_prompt_name)
        expect(result).to have_attributes(
          llm_guardrail_result: 'True | "1, 2"',
          guardrails: { costs: true, personal: true, unique_answer_guardrail: false },
          triggered: true,
        )
      end

      it "returns a false result with no matched guardrails" do
        stub_claude_output_guardrails(input)

        result = described_class.call(input, llm_prompt_name)

        expect(result).to have_attributes(
          llm_guardrail_result: "False | None",
          guardrails: { costs: false, personal: false, unique_answer_guardrail: false },
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
          content: [claude_messages_text_block('True | "1, 2"')],
          usage: { cache_read_input_tokens: 20 },
          bedrock_model: described_class::DEFAULT_MODEL,
        ).to_h
        expect(result.llm_response).to eq(expected_llm_response)
      end

      it "returns the model used" do
        result = described_class.call(input, llm_prompt_name)
        expect(result.model).to eq(BedrockModels.model_id(described_class::DEFAULT_MODEL))
      end
    end

    context "when the response format is incorrect" do
      let(:llm_guardrail_result) { 'False | "1, 2"' }

      it "throws a ResponseError" do
        stub_claude_output_guardrails(input, llm_guardrail_result)

        expected_llm_response = claude_messages_response(
          content: [claude_messages_text_block(llm_guardrail_result)],
          usage: { cache_read_input_tokens: 20 },
          bedrock_model: described_class::DEFAULT_MODEL,
        ).to_h
        expect { described_class.call(input, llm_prompt_name) }
          .to raise_error(
            an_instance_of(AnswerComposition::MultipleGuardrail::ResponseError)
              .and(having_attributes(message: "Error parsing guardrail response",
                                     llm_guardrail_result:,
                                     llm_response: expected_llm_response)),
          )
      end
    end

    context "when the response contains an unknown guardrail number" do
      let(:llm_guardrail_result) { 'False | "1, 8"' }

      it "throws a ResponseError" do
        stub_claude_output_guardrails(input, llm_guardrail_result)

        expected_llm_response = claude_messages_response(
          content: [claude_messages_text_block(llm_guardrail_result)],
          usage: { cache_read_input_tokens: 20 },
          bedrock_model: described_class::DEFAULT_MODEL,
        ).to_h
        expect { described_class.call(input, llm_prompt_name) }
          .to raise_error(
            an_instance_of(AnswerComposition::MultipleGuardrail::ResponseError)
              .and(having_attributes(message: "Error parsing guardrail response",
                                     llm_guardrail_result:,
                                     llm_response: expected_llm_response)),
          )
      end
    end
  end
end
