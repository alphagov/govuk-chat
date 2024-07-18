RSpec.describe OutputGuardrails::FewShot do
  let(:guardrail_mappings) { { "1" => "COSTS", "5" => "PERSONAL" } }

  before do
    allow(Rails.logger).to receive(:error)
    allow(Rails.configuration.llm_prompts.output_guardrails.few_shot).to receive(:guardrail_mappings).and_return(guardrail_mappings)
  end

  context "when the request is successful" do
    let(:input) { "This is a test input." }
    let(:expected_messages) do
      [
        { role: "system", content: system_prompt },
        {
          role: "user",
          content: Rails.configuration.llm_prompts.output_guardrails.few_shot.user_prompt.sub("{input}", input),
        },
      ]
    end

    it "returns triggered: true with human readable guardrails" do
      guardrail_result = 'True | "1, 5"'
      stub_openai_chat_completion(expected_messages, guardrail_result, chat_options: {
        model: "gpt-4o",
        max_tokens: 25, # It takes 23 tokens for True | "1, 2, 3, 4, 5, 6, 7"
      })
      expect(described_class.call(input)).to be_a(OutputGuardrails::FewShot::Result)
        .and(having_attributes(
               triggered: true,
               guardrails: %w[COSTS PERSONAL],
               llm_response: guardrail_result,
             ))
    end

    it "returns triggered: false with empty guardrails" do
      guardrail_result = "False | None"
      stub_openai_chat_completion(expected_messages, guardrail_result, chat_options: {
        model: "gpt-4o",
        max_tokens: 25,
      })
      expect(described_class.call(input)).to be_a(OutputGuardrails::FewShot::Result)
        .and(having_attributes(
               triggered: false,
               guardrails: [],
               llm_response: guardrail_result,
             ))
    end

    context "when the OpenAI response format is incorrect" do
      it "throws a AnswerComposition::OutputGuardrails::ResponseError" do
        guardrail_result = 'False | "1, 2"'
        stub_openai_chat_completion(expected_messages, guardrail_result, chat_options: {
          model: "gpt-4o",
          max_tokens: 25,
        })
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
        stub_openai_chat_completion(expected_messages, guardrail_result, chat_options: {
          model: "gpt-4o",
          max_tokens: 25,
        })
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

  def system_prompt
    Rails.configuration.llm_prompts.output_guardrails.few_shot.system_prompt
      .gsub("{date}", Time.zone.today.strftime("%A %d %B %Y"))
  end
end
