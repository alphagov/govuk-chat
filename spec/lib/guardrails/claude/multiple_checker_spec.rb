RSpec.describe Guardrails::Claude::MultipleChecker do
  let(:input) { "This is a test input." }
  let(:formatted_date) { Date.current.strftime("%A %d %B %Y") }

  describe ".call" do
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
      let(:prompt) { instance_double(Guardrails::MultipleChecker::Prompt) }

      before do
        allow(Rails.logger).to receive(:error)
        allow(guardrails_config).to receive(:[]).with(llm_prompt_name).and_return(
          guardrails:,
          guardrail_definitions:,
          system_prompt: "{guardrails} {date}",
          user_prompt: "{input}",
        )

        allow(Guardrails::MultipleChecker::Prompt).to receive(:new).with(llm_prompt_name, :claude).and_return(prompt)

        guardrail_objects = guardrails.map.with_index(1) do |name, key|
          Guardrails::MultipleChecker::Prompt::Guardrail.new(
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

      it "calls Claude to check for guardrail violations with the correct system prompt and the input in the user prompt" do
        guardrail_result = 'True | "1, 2"'

        client = stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )

        described_class.call(input, prompt)
        expect(client.api_requests.size).to eq(1)
      end

      it "returns a true result with human readable guardrails" do
        guardrail_result = 'True | "1, 2"'

        stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )

        result = described_class.call(input, prompt)
        expect(result[:llm_guardrail_result]).to eq(guardrail_result)
      end

      it "returns a false result with empty guardrails" do
        guardrail_result = "False | None"

        stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )

        result = described_class.call(input, prompt)
        expect(result[:llm_guardrail_result]).to eq(guardrail_result)
      end

      it "returns the LLM token usage" do
        guardrail_result = "False | None"

        stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )
        result = described_class.call(input, prompt)

        expect(result[:llm_token_usage].input_tokens).to eq(10)
        expect(result[:llm_token_usage].output_tokens).to eq(20)
        expect(result[:llm_token_usage].total_tokens).to eq(30)
      end
    end

    context "with a non-existent llm_prompt_name" do
      let(:llm_prompt_name) { "non_existent_llm_prompt_name" }

      it "raises an error" do
        guardrail_result = "False | None"

        stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )

        expect { Guardrails::MultipleChecker::Prompt.new(llm_prompt_name, :claude) }
        .to raise_error("No LLM prompts found for #{llm_prompt_name}")
      end
    end
  end
end
