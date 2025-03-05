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

      it "returns triggered: false with empty guardrails" do
        guardrail_result = "False | None"

        stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )

        result = described_class.call(input, llm_prompt_name)

        expect(result)
          .to be_a(::Guardrails::MultipleChecker::Result)
          .and(having_attributes(
                 triggered: false,
                 guardrails: [],
                 llm_guardrail_result: guardrail_result,
               ))

        expect(result.llm_response.message.content.first.text)
        .to eq(guardrail_result)
      end

      it "returns the LLM token usage" do
        guardrail_result = "False | None"

        stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )
        result = described_class.call(input, llm_prompt_name)

        expect(result.llm_token_usage.input_tokens).to eq(10)
        expect(result.llm_token_usage.output_tokens).to eq(20)
        expect(result.llm_token_usage.total_tokens).to eq(30)
      end

      context "when the Claude response format is incorrect" do
        it "throws a ResponseError" do
          guardrail_result = 'False | "1, 2"'
          stub_bedrock_converse(
            bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
          )
          expect { described_class.call(input, llm_prompt_name) }
            .to raise_error(
              an_instance_of(::Guardrails::MultipleChecker::ResponseError)
                .and(having_attributes(message: "Error parsing guardrail response",
                                       llm_response: guardrail_result)),
            )
        end
      end

      context "when the Claude response contains an unknown guardrail number" do
        it "throws a ResponseError" do
          guardrail_result = 'False | "1, 8"'
          stub_bedrock_converse(
            bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
          )
          expect { described_class.call(input, llm_prompt_name) }
            .to raise_error(
              an_instance_of(::Guardrails::MultipleChecker::ResponseError)
                .and(having_attributes(message: "Error parsing guardrail response",
                                       llm_response: guardrail_result)),
            )
        end
      end
    end

    context "with a non-existent llm_prompt_name" do
      let(:llm_prompt_name) { "non_existent_llm_prompt_name" }

      it "raises an error" do
        guardrail_result = "False | None"

        stub_bedrock_converse(
          bedrock_claude_text_response(guardrail_result, user_message: Regexp.new(input)),
        )

        expect { described_class.call(input, llm_prompt_name) }
        .to raise_error("No LLM prompts found for #{llm_prompt_name}")
      end
    end
  end
end
