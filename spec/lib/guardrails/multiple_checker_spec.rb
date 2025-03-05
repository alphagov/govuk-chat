RSpec.describe Guardrails::MultipleChecker do
  let(:input) { "This is a test input." }
  let(:formatted_date) { Date.current.strftime("%A %d %B %Y") }

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
      allow(Rails.configuration.govuk_chat_private.llm_prompts.openai).to receive(:[]).with(llm_prompt_name).and_return(guardrails_config)
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

        expect(described_class.collated_prompts(llm_prompt_name, :openai)).to eq(expected_prompt)
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

        expect(described_class.collated_prompts(llm_prompt_name, :openai)).to eq(expected_prompt)
      end
    end
  end
end
