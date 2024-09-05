RSpec.describe OutputGuardrails::FewShot do
  let(:guardrail_mappings) { { "1" => "COSTS", "5" => "PERSONAL" } }

  let(:formatted_date) { Date.current.strftime("%A %d %B %Y") }
  let(:system_prompt) do
    Rails.configuration.llm_prompts.output_guardrails.dig(:few_shot, :system_prompt)
      .gsub("{date}", formatted_date)
  end

  before do
    allow(Rails.logger).to receive(:error)
    allow(Rails.configuration.llm_prompts.output_guardrails).to receive(:dig).and_call_original
    allow(Rails.configuration.llm_prompts.output_guardrails).to receive(:dig).with(:few_shot, :guardrail_mappings)
                                                            .and_return(guardrail_mappings)
  end

  context "when the request is successful" do
    let(:input) { "This is a test input." }

    it "calls OpenAI to check for guardrail violations, including the date in the system prompt and the input in the user prompt" do
      messages = array_including(
        { "role" => "system", "content" => a_string_including(formatted_date) },
        { "role" => "user", "content" => a_string_including(input) },
      )
      openai_request = stub_openai_chat_completion(messages, answer: "False | None", chat_options: {
        model: OutputGuardrails::FewShot::OPENAI_MODEL,
        max_tokens: OutputGuardrails::FewShot::OPENAI_MAX_TOKENS,
      })

      described_class.call(input)
      expect(openai_request).to have_been_made
    end

    it "returns triggered: true with human readable guardrails" do
      guardrail_result = 'True | "1, 5"'
      stub_openai_output_guardrail(input, guardrail_result)
      expect(described_class.call(input)).to be_a(OutputGuardrails::FewShot::Result)
        .and(having_attributes(
               triggered: true,
               guardrails: %w[COSTS PERSONAL],
               llm_response: guardrail_result,
             ))
    end

    it "returns triggered: false with empty guardrails" do
      guardrail_result = "False | None"
      stub_openai_output_guardrail(input, guardrail_result)
      expect(described_class.call(input)).to be_a(OutputGuardrails::FewShot::Result)
        .and(having_attributes(
               triggered: false,
               guardrails: [],
               llm_response: guardrail_result,
             ))
    end

    it "returns the LLM token usage" do
      stub_openai_output_guardrail(input)
      result = described_class.call(input)

      expect(result.llm_token_usage).to eq({
        "prompt_tokens" => 13,
        "completion_tokens" => 7,
        "total_tokens" => 20,
      })
    end

    context "when the OpenAI response format is incorrect" do
      it "throws a AnswerComposition::OutputGuardrails::ResponseError" do
        guardrail_result = 'False | "1, 2"'
        stub_openai_output_guardrail(input, guardrail_result)
        expect { described_class.call(input) }
          .to raise_error(
            an_instance_of(OutputGuardrails::FewShot::ResponseError)
              .and(having_attributes(message: "Error parsing guardrail response",
                                     llm_response: guardrail_result)),
          )
      end
    end

    context "when the OpenAI response contains an unknown guardrail number" do
      it "throws a AnswerComposition::OutputGuardrails::ResponseError" do
        guardrail_result = 'False | "1, 8"'
        stub_openai_output_guardrail(input, guardrail_result)
        expect { described_class.call(input) }
          .to raise_error(
            an_instance_of(OutputGuardrails::FewShot::ResponseError)
              .and(having_attributes(message: "Error parsing guardrail response",
                                     llm_response: guardrail_result)),
          )
      end
    end

    context "when there is an OpenAIClient::ClientError" do
      before do
        stub_openai_chat_completion_error
      end

      it "raises a OpenAIClient::RequestError with a modified message" do
        expect { described_class.call(input) }
          .to raise_error(
            an_instance_of(OpenAIClient::RequestError)
              .and(having_attributes(response: an_instance_of(Hash),
                                     message: "could not run guardrail: This is a test input.",
                                     cause: an_instance_of(OpenAIClient::ClientError))),
          )
      end
    end

    context "when there is an OpenAIClient::ContextLengthExceededError" do
      before do
        stub_openai_chat_completion_error(code: "context_length_exceeded")
      end

      it "raises a OpenAIClient::ContextLengthExceededError with a modified message" do
        expect { described_class.call(input) }
          .to raise_error(
            an_instance_of(OpenAIClient::ContextLengthExceededError)
              .and(having_attributes(response: an_instance_of(Hash),
                                     message: "Exceeded context length running guardrail: This is a test input.",
                                     cause: an_instance_of(OpenAIClient::ContextLengthExceededError))),
          )
      end
    end
  end
end
