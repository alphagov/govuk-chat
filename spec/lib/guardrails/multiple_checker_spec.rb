RSpec.describe Guardrails::MultipleChecker do
  let(:input) { "This is a test input." }
  let(:formatted_date) { Date.current.strftime("%A %d %B %Y") }

  describe ".call" do
    let(:input) { "This is a test input." }
    let(:llm_prompt_name) { :answer_guardrails }
    let(:guardrail_response_hash) do
      {
        llm_response: {
          message: {
            role: "assistant",
            content: "False | None",
          },
          finish_reason: "stop",
        },
        llm_guardrail_result: "False | None",
        llm_prompt_tokens: 13,
        llm_completion_tokens: 7,
        llm_cached_tokens: 10,
        model: "gpt-4o-mini-2024-07-18",
      }
    end
    let(:guardrail_result) { build(:guardrails_multiple_checker_result, :pass) }

    it "raises an error if the llm_provider is unknown" do
      expect { described_class.call(input, llm_prompt_name, :unknown_provider) }
        .to raise_error(RuntimeError, "Unexpected provider unknown_provider")
    end

    context "when the llm_provider is :openai" do
      let(:llm_provider) { :openai }

      before do
        guardrails_config = {
          system_prompt: "{guardrails} {date}",
          user_prompt: "{input}",
          guardrails: %w[political appropriate_language],
          guardrail_definitions: {
            "political" => "This is a political guardrail",
            "appropriate_language" => "This is an appropriate language guardrail",
          },
        }.with_indifferent_access

        allow(Rails.configuration.govuk_chat_private.llm_prompts.openai).to receive(:[]).with(llm_prompt_name).and_return(guardrails_config)
        allow(Guardrails::OpenAI::MultipleChecker).to receive(:call).and_return(guardrail_response_hash)
      end

      it "calls the OpenAI multiple checker" do
        described_class.call(input, llm_prompt_name, llm_provider)
        expect(Guardrails::OpenAI::MultipleChecker).to have_received(:call).with(input, instance_of(Guardrails::MultipleChecker::Prompt))
      end

      it "returns the guardrail result" do
        result = described_class.call(input, llm_prompt_name, llm_provider)
        expect(result).to eq(guardrail_result)
      end
    end

    context "when the llm_provider is :claude" do
      let(:llm_provider) { :claude }

      before do
        guardrails_config = {
          system_prompt: "{guardrails} {date}",
          user_prompt: "{input}",
          guardrails: %w[political appropriate_language],
          guardrail_definitions: {
            "political" => "This is a political guardrail",
            "appropriate_language" => "This is an appropriate language guardrail",
          },
        }.with_indifferent_access

        allow(AnswerComposition::Pipeline::Claude).to receive(:prompt_config)
                                                  .with(llm_prompt_name, Guardrails::Claude::MultipleChecker.bedrock_model)
                                                  .and_return(guardrails_config)
        allow(Guardrails::Claude::MultipleChecker).to receive(:call).and_return(guardrail_response_hash)
      end

      it "calls the Claude multiple checker" do
        described_class.call(input, llm_prompt_name, llm_provider)
        expect(Guardrails::Claude::MultipleChecker).to have_received(:call).with(input, instance_of(Guardrails::MultipleChecker::Prompt))
      end

      it "returns the guardrail result" do
        result = described_class.call(input, llm_prompt_name, llm_provider)
        expect(result).to eq(guardrail_result)
      end

      context "when the response format is incorrect" do
        it "throws a ResponseError" do
          guardrail_result = 'False | "1, 2"'
          guardrail_response_hash[:llm_guardrail_result] = guardrail_result
          allow(Guardrails::Claude::MultipleChecker).to receive(:call).and_return(guardrail_response_hash)

          expect { described_class.call(input, llm_prompt_name, llm_provider) }
            .to raise_error(
              an_instance_of(::Guardrails::MultipleChecker::ResponseError)
                .and(having_attributes(message: "Error parsing guardrail response",
                                       llm_guardrail_result: guardrail_result,
                                       llm_response: guardrail_response_hash[:llm_response])),
            )
        end
      end

      context "when the response contains an unknown guardrail number" do
        it "throws a ResponseError" do
          guardrail_result = 'False | "1, 8"'
          guardrail_response_hash[:llm_guardrail_result] = guardrail_result
          allow(Guardrails::Claude::MultipleChecker).to receive(:call).and_return(guardrail_response_hash)

          expect { described_class.call(input, llm_prompt_name, llm_provider) }
            .to raise_error(
              an_instance_of(::Guardrails::MultipleChecker::ResponseError)
                .and(having_attributes(message: "Error parsing guardrail response",
                                       llm_guardrail_result: guardrail_result,
                                       llm_response: guardrail_response_hash[:llm_response])),
            )
        end
      end
    end
  end

  describe ".collated_prompts" do
    let(:system_prompt) do
      <<~PROMPT
        This is the date:

        {date}

        These are the guardrails:

        {guardrails}
      PROMPT
    end
    let(:user_prompt) do
      <<~PROMPT
        This is the user prompt:

        {input}
      PROMPT
    end

    before do
      guardrails_config = { system_prompt:, user_prompt:, guardrails:, guardrail_definitions: }.with_indifferent_access
      allow(AnswerComposition::Pipeline::Claude).to receive(:prompt_config)
                                          .with(llm_prompt_name, Guardrails::Claude::MultipleChecker.bedrock_model)
                                          .and_return(guardrails_config)
    end

    context "when the llm_prompt_name is :answer_guardrails" do
      let(:llm_prompt_name) { :answer_guardrails }
      let(:guardrail_definitions) do
        {
          "costs" => "This is a costs guardrail",
          "personal" => "This is a personal guardrail",
          "unique_answer_guardrail" => "This is a unique answer guardrail",
        }
      end
      let(:guardrails) { %w[costs personal unique_answer_guardrail] }

      it "returns the correct prompt template" do
        expected_prompt = <<~PROMPT
          # System prompt

          This is the date:

          #{formatted_date}

          These are the guardrails:

          1. This is a costs guardrail
          2. This is a personal guardrail
          3. This is a unique answer guardrail

          # User prompt

          This is the user prompt:

          <insert answer to check>

        PROMPT

        expect(described_class.collated_prompts(llm_prompt_name, :claude)).to eq(expected_prompt)
      end
    end

    context "when the llm_prompt_name is :question_routing_guardrails" do
      let(:llm_prompt_name) { :question_routing_guardrails }
      let(:guardrail_definitions) do
        {
          "unique_question_routing_guardrail" => "This is a unique question routing guardrail",
        }
      end
      let(:guardrails) { %w[unique_question_routing_guardrail] }

      it "returns the correct prompt template" do
        expected_prompt = <<~PROMPT
          # System prompt

          This is the date:

          #{formatted_date}

          These are the guardrails:

          1. This is a unique question routing guardrail

          # User prompt

          This is the user prompt:

          <insert answer to check>

        PROMPT

        expect(described_class.collated_prompts(llm_prompt_name, :claude)).to eq(expected_prompt)
      end
    end
  end
end
