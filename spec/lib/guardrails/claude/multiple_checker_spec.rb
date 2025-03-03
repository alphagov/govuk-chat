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

      before do
        allow(Rails.logger).to receive(:error)
        allow(guardrails_config).to receive(:[]).with(llm_prompt_name).and_return(
          guardrails:,
          guardrail_definitions:,
          system_prompt: "{guardrails} {date}",
          user_prompt: "{input}",
        )
      end

      it "calls Claude to check for guardrail violations with the correct system prompt and the input in the user prompt" do
        guardrail_result = 'True | "1, 2"'

        client = stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )

        described_class.call(input, llm_prompt_name)
        expect(client.api_requests.size).to eq(1)
      end

      it "returns triggered: true with human readable guardrails" do
        guardrail_result = 'True | "1, 2"'

        stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )

        result = described_class.call(input, llm_prompt_name)

        expect(result)
          .to be_a(::Guardrails::MultipleChecker::Result)
          .and(having_attributes(
                 triggered: true,
                 guardrails: %w[costs personal],
                 llm_guardrail_result: guardrail_result,
               ))

        expect(result.llm_response.message.content.first.text)
        .to eq(guardrail_result)
      end
    end
  end
end
