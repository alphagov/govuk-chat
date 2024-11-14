RSpec.describe Guardrails::MultipleChecker do
  describe ".call" do
    let(:input) { "This is a test input." }
    let(:formatted_date) { Date.current.strftime("%A %d %B %Y") }
    let(:llm_prompt_name) { :answer_guardrails }

    context "when the request is successful" do
      let(:guardrails_config) { Rails.configuration.llm_prompts.public_send(llm_prompt_name) }
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
        allow(guardrails_config).to receive(:fetch).and_call_original
        allow(guardrails_config).to receive(:fetch).with(:guardrails).and_return(guardrails)
        allow(guardrails_config).to receive(:fetch).with(:guardrail_definitions).and_return(guardrail_definitions)
      end

      it "calls OpenAI to check for guardrail violations with the correct system prompt and the input in the user prompt" do
        expected_answer_guardrails = "1. This is a costs guardrail\n2. This is a personal guardrail\n3. This is a unique answer guardrail"
        messages = array_including(
          { "role" => "system", "content" => a_string_including(expected_answer_guardrails, formatted_date) },
          { "role" => "user", "content" => a_string_including(input) },
        )
        openai_request = stub_openai_chat_completion(messages, answer: "False | None", chat_options: {
          model: described_class::OPENAI_MODEL,
        })

        described_class.call(input, llm_prompt_name)
        expect(openai_request).to have_been_made
      end

      it "returns triggered: true with human readable guardrails" do
        guardrail_result = 'True | "1, 2"'
        stub_openai_output_guardrail(input, guardrail_result)
        expect(described_class.call(input, llm_prompt_name)).to be_a(described_class::Result)
          .and(having_attributes(
                 triggered: true,
                 guardrails: %w[costs personal],
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
        longest_possible_response_string = %(True | "#{(1..guardrails.count).to_a.join(', ')}")
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

      it "throws an error if a guardrail definition is missing for a guardrail" do
        guardrail_definitions.delete("costs")
        expect { described_class.call(input, llm_prompt_name) }.to raise_error(KeyError)
      end

      context "when :question_routing_guardrails is passed in as the llm_prompt_name" do
        let(:llm_prompt_name) { :question_routing_guardrails }
        let(:guardrail_definitions) do
          {
            "costs" => "This is a costs guardrail",
            "personal" => "This is a personal guardrail",
            "unique_question_routing_guardrail" => "This is a unique question routing guardrail",
          }
        end
        let(:guardrails) { %w[costs personal unique_question_routing_guardrail] }

        it "uses the correct guardrails for question routing" do
          expected_question_routing_guardrails = "1. This is a costs guardrail\n2. This is a personal guardrail\n3. This is a unique question routing guardrail"
          messages = array_including(
            { "role" => "system", "content" => a_string_including(expected_question_routing_guardrails, formatted_date) },
            { "role" => "user", "content" => a_string_including(input) },
          )
          openai_request = stub_openai_chat_completion(messages, answer: "False | None", chat_options: {})

          described_class.call(input, llm_prompt_name)

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
