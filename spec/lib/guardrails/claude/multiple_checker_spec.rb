RSpec.describe Guardrails::Claude::MultipleChecker, :aws_credentials_stubbed do
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

      it "calls Claude to check for guardrail violations with correct user input" do
        anthropic_request = stub_claude_output_guardrails(input, 'True | "1, 2"')

        described_class.call(input, prompt)

        expect(anthropic_request).to have_been_made
      end

      it "returns a true result with matched guardrails" do
        stub_claude_output_guardrails(input, 'True | "1, 2"')

        result = described_class.call(input, prompt)

        expect(result[:llm_guardrail_result]).to eq('True | "1, 2"')
      end

      it "returns a false result with no matched guardrails" do
        stub_claude_output_guardrails(input, "False | None")

        result = described_class.call(input, prompt)

        expect(result[:llm_guardrail_result]).to eq("False | None")
      end

      it "returns the LLM token usage" do
        stub_claude_output_guardrails(input, "False | None")

        result = described_class.call(input, prompt)

        expect(result[:llm_prompt_tokens]).to eq(30)
        expect(result[:llm_completion_tokens]).to eq(20)
        expect(result[:llm_cached_tokens]).to eq(20)
        expect(result[:model]).to eq(BedrockModels.model_id(:claude_sonnet_4_0))
      end

      it "returns the model used" do
        stub_claude_output_guardrails(input, "False | None")

        result = described_class.call(input, prompt)

        expect(result[:model]).to eq(BedrockModels.model_id(:claude_sonnet_4_0))
      end

      it "uses an overridden AWS region if set" do
        ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
          allow(Anthropic::BedrockClient).to receive(:new).and_call_original
          anthropic_request = stub_claude_output_guardrails(input, "False | None")

          described_class.call(input, prompt)

          expect(Anthropic::BedrockClient).to have_received(:new).with(hash_including(aws_region: "my-region"))
          expect(anthropic_request).to have_been_made
        end
      end
    end

    context "with a non-existent llm_prompt_name" do
      let(:llm_prompt_name) { "non_existent_llm_prompt_name" }

      it "raises an error" do
        stub_claude_output_guardrails(input, "False | None")

        expect {
          Guardrails::MultipleChecker::Prompt.new(llm_prompt_name, :claude)
        }.to raise_error("No LLM prompts found for #{llm_prompt_name}")
      end
    end
  end
end
