RSpec.describe Guardrails::MultipleChecker do
  describe ".call" do
    let(:guardrail_mappings) { { "1" => "COSTS", "5" => "PERSONAL" } }
    let(:input) { "This is a test input." }

    let(:formatted_date) { Date.current.strftime("%A %d %B %Y") }
    let(:llm_prompt_name) { :answer_guardrails }
    let(:system_prompt) do
      Rails.configuration.llm_prompts.dig(llm_prompt_name, :system_prompt)
        .gsub("{date}", formatted_date)
    end

    before do
      allow(Rails.logger).to receive(:error)
      allow(Rails.configuration.llm_prompts.answer_guardrails).to receive(:fetch).and_call_original
      allow(Rails.configuration.llm_prompts.answer_guardrails).to receive(:fetch).with(:guardrail_mappings)
                                                              .and_return(guardrail_mappings)
    end

    context "when the request is successful" do
      it "calls OpenAI to check for guardrail violations, including the date in the system prompt and the input in the user prompt" do
        messages = array_including(
          { "role" => "system", "content" => a_string_including(formatted_date) },
          { "role" => "user", "content" => a_string_including(input) },
        )
        openai_request = stub_openai_chat_completion(messages, answer: "False | None", chat_options: {
          model: described_class::OPENAI_MODEL,
        })

        described_class.call(input, llm_prompt_name)
        expect(openai_request).to have_been_made
      end

      it "returns triggered: true with human readable guardrails" do
        guardrail_result = 'True | "1, 5"'
        stub_openai_output_guardrail(input, guardrail_result)
        expect(described_class.call(input, llm_prompt_name)).to be_a(described_class::Result)
          .and(having_attributes(
                triggered: true,
                guardrails: %w[COSTS PERSONAL],
                llm_response: a_hash_including(
                  "message" => a_hash_including("content" => guardrail_result),
                ),
                llm_guardrail_result: guardrail_result,
              ))
      end

      it "returns triggered: false with empty guardrails" do
        guardrail_result = "False | None"
        stub_openai_output_guardrail(input, guardrail_result)
        expect(described_class.call(input, llm_prompt_name)).to be_a(described_class::Result)
          .and(having_attributes(
                triggered: false,
                guardrails: [],
                llm_response: a_hash_including(
                  "message" => a_hash_including("content" => guardrail_result),
                ),
                llm_guardrail_result: guardrail_result,
              ))
      end

      it "returns the LLM token usage" do
        stub_openai_output_guardrail(input)
        result = described_class.call(input, llm_prompt_name)

        expect(result.llm_token_usage).to eq({
          "prompt_tokens" => 13,
          "completion_tokens" => 7,
          "total_tokens" => 20,
          "prompt_tokens_details" => { "cached_tokens" => 10 },
        })
      end

      it "calculates the max_tokens param from the guardrail config" do
        longest_possible_response_string = %(True | "#{guardrail_mappings.keys.join(', ')}")
        token_count = Tiktoken
                        .encoding_for_model(described_class::OPENAI_MODEL)
                        .encode(longest_possible_response_string)
                        .length

        max_tokens = token_count + described_class::MAX_TOKENS_BUFFER

        openai_request = stub_openai_chat_completion(
          anything,
          answer: "False | None",
          chat_options: { max_tokens: },
        )

        described_class.call(input, llm_prompt_name)

        expect(openai_request).to have_been_made
      end

      context "with a question routing guardrail LLM prompt" do
        it "makes the request" do
          messages = array_including(
            { "role" => "system", "content" => a_string_including(formatted_date) },
            { "role" => "user", "content" => a_string_including(input) },
          )
          openai_request = stub_openai_chat_completion(messages, answer: "False | None", chat_options: {})

          described_class.call(input, :question_routing_guardrails)

          expect(openai_request).to have_been_made
        end
      end

      context "when the OpenAI response format is incorrect" do
        it "throws a ResponseError" do
          guardrail_result = 'False | "1, 2"'
          stub_openai_output_guardrail(input, guardrail_result)
          expect { described_class.call(input, llm_prompt_name) }
            .to raise_error(
              an_instance_of(described_class::ResponseError)
                .and(having_attributes(message: "Error parsing guardrail response",
                                      llm_response: guardrail_result)),
            )
        end
      end

      context "when the OpenAI response contains an unknown guardrail number" do
        it "throws a ResponseError" do
          guardrail_result = 'False | "1, 8"'
          stub_openai_output_guardrail(input, guardrail_result)
          expect { described_class.call(input, llm_prompt_name) }
            .to raise_error(
              an_instance_of(described_class::ResponseError)
                .and(having_attributes(message: "Error parsing guardrail response",
                                      llm_response: guardrail_result)),
            )
        end
      end
    end

    context "with a non-existent llm_prompt_name" do
      let(:llm_prompt_name) { "non_existent_llm_prompt_name" }

      it "raises an error" do
        expect { described_class.call(input, llm_prompt_name) }
          .to raise_error("No LLM prompts found for #{llm_prompt_name}")
      end
    end
  end
end
