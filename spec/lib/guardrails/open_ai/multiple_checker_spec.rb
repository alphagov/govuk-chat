RSpec.describe Guardrails::OpenAI::MultipleChecker do
  let(:input) { "This is a test input." }
  let(:formatted_date) { Date.current.strftime("%A %d %B %Y") }

  describe ".call" do
    context "when the request is successful" do
      let(:llm_prompt_name) { :answer_guardrails }
      let(:guardrails_config) { Rails.configuration.govuk_chat_private.llm_prompts.openai }
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

        allow(Guardrails::MultipleChecker::Prompt).to receive(:new).with(llm_prompt_name, :openai).and_return(prompt)

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

      it "throws an error if a guardrail definition is missing for a guardrail" do
        guardrail_definitions.delete("costs")
        allow(prompt).to receive(:guardrails).and_raise(KeyError)
        expect { described_class.call(input, prompt) }.to raise_error(KeyError)
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

        described_class.call(input, prompt)
        expect(openai_request).to have_been_made
      end

      it "returns triggered: true with human readable guardrails" do
        guardrail_result = 'True | "1, 2"'
        stub_openai_output_guardrail(input, guardrail_result)
        expect(described_class.call(input, prompt))
          .to be_a(::Guardrails::MultipleChecker::Result)
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
        expect(described_class.call(input, prompt))
          .to be_a(::Guardrails::MultipleChecker::Result)
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
        result = described_class.call(input, prompt)

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

        described_class.call(input, prompt)
        expect(openai_request).to have_been_made
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
        let(:question_routing_prompt) { instance_double(Guardrails::MultipleChecker::Prompt) }

        before do
          allow(Guardrails::MultipleChecker::Prompt).to receive(:new).with(llm_prompt_name, :openai).and_return(question_routing_prompt)

          question_routing_guardrail_objects = guardrails.map.with_index(1) do |name, key|
            Guardrails::MultipleChecker::Prompt::Guardrail.new(
              key: key,
              name: name,
              content: guardrail_definitions[name],
            )
          end

          allow(question_routing_prompt).to receive_messages(
            system_prompt: "1. This is a costs guardrail\n2. This is a personal guardrail\n3. This is a unique question routing guardrail #{formatted_date}",
            guardrails: question_routing_guardrail_objects,
          )
          allow(question_routing_prompt).to receive(:user_prompt).with(input).and_return(input)
        end

        it "uses the correct guardrails for question routing" do
          expected_question_routing_guardrails = "1. This is a costs guardrail\n2. This is a personal guardrail\n3. This is a unique question routing guardrail"
          messages = array_including(
            { "role" => "system", "content" => a_string_including(expected_question_routing_guardrails, formatted_date) },
            { "role" => "user", "content" => a_string_including(input) },
          )
          openai_request = stub_openai_chat_completion(messages, answer: "False | None", chat_options: {})

          described_class.call(input, question_routing_prompt)

          expect(openai_request).to have_been_made
        end
      end

      context "when the OpenAI response format is incorrect" do
        it "throws a ResponseError" do
          guardrail_result = 'False | "1, 2"'
          stub_openai_output_guardrail(input, guardrail_result)
          expect { described_class.call(input, prompt) }
            .to raise_error(
              an_instance_of(::Guardrails::MultipleChecker::ResponseError)
                .and(having_attributes(message: "Error parsing guardrail response",
                                       llm_response: guardrail_result)),
            )
        end
      end

      context "when the OpenAI response contains an unknown guardrail number" do
        it "throws a ResponseError" do
          guardrail_result = 'False | "1, 8"'
          stub_openai_output_guardrail(input, guardrail_result)
          expect { described_class.call(input, prompt) }
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
        expect { Guardrails::MultipleChecker::Prompt.new(llm_prompt_name, :openai) }
          .to raise_error("No LLM prompts found for #{llm_prompt_name}")
      end
    end
  end
end
