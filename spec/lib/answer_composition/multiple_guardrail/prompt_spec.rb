RSpec.describe AnswerComposition::MultipleGuardrail::Prompt do
  let(:formatted_date) { Date.current.strftime("%A %d %B %Y") }
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
  let(:guardrails) { %w[costs personal unique_answer_guardrail] }
  let(:guardrail_definitions) do
    {
      "costs" => "This is a costs guardrail",
      "personal" => "This is a personal guardrail",
      "unique_answer_guardrail" => "This is a unique answer guardrail",
    }
  end
  let(:guardrails_config) do
    {
      system_prompt:,
      user_prompt:,
      guardrails:,
      guardrail_definitions:,
    }.with_indifferent_access
  end

  shared_examples "a prompt with guardrails" do |llm_prompt_name|
    before do
      allow(AnswerComposition::Pipeline::Prompts)
        .to receive(:config)
        .with(llm_prompt_name, AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL)
        .and_return(guardrails_config)
    end

    describe "#system_prompt" do
      it "returns the system prompt with guardrails and date interpolated" do
        prompt = described_class.new(llm_prompt_name)
        expected_guardrails_content = prompt.guardrails.map { |g| "#{g.key}. #{g.content}" }
                                                       .join("\n")

        expected_system_prompt = system_prompt
                                 .sub("{date}", formatted_date)
                                 .sub("{guardrails}", expected_guardrails_content)

        expect(prompt.system_prompt).to eq(expected_system_prompt)
      end
    end

    describe "#user_prompt" do
      it "returns the user prompt with input interpolated" do
        prompt = described_class.new(llm_prompt_name)
        input = "This is a test input"
        expected_user_prompt = user_prompt.sub("{input}", input)

        expect(prompt.user_prompt(input)).to eq(expected_user_prompt)
      end
    end

    describe "#guardrails" do
      it "returns an array of Guardrail instances with the correct attributes" do
        prompt = described_class.new(llm_prompt_name)
        guardrails = prompt.guardrails

        expect(guardrails.length).to eq(3)
        expect(guardrails.first)
          .to be_a(AnswerComposition::MultipleGuardrail::Prompt::Guardrail)
          .and have_attributes(key: 1, name: "costs", content: "This is a costs guardrail")

        expect(guardrails.second)
          .to be_a(AnswerComposition::MultipleGuardrail::Prompt::Guardrail)
          .and have_attributes(key: 2, name: "personal", content: "This is a personal guardrail")

        expect(guardrails.third)
          .to be_a(AnswerComposition::MultipleGuardrail::Prompt::Guardrail)
          .and have_attributes(key: 3, name: "unique_answer_guardrail", content: "This is a unique answer guardrail")
      end
    end
  end

  it_behaves_like "a prompt with guardrails", :answer_guardrails
  it_behaves_like "a prompt with guardrails", :question_routing_guardrails

  describe "#initialize" do
    it "raises an error if no prompts are found for the given name" do
      expect {
        described_class.new("non_existent_llm_prompt_name")
      }.to raise_error("No LLM prompts found for non_existent_llm_prompt_name")
    end
  end

  describe ".collated" do
    context "when the llm_prompt_name is :answer_guardrails" do
      let(:llm_prompt_name) { :answer_guardrails }

      before do
        allow(AnswerComposition::Pipeline::Prompts).to receive(:config)
                                                   .with(llm_prompt_name, AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL)
                                                   .and_return(guardrails_config)
      end

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

        expect(described_class.collated(llm_prompt_name)).to eq(expected_prompt)
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

      before do
        allow(AnswerComposition::Pipeline::Prompts).to receive(:config)
                                                   .with(llm_prompt_name, AnswerComposition::MultipleGuardrail::Checker::DEFAULT_MODEL)
                                                   .and_return(guardrails_config)
      end

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

        expect(described_class.collated(llm_prompt_name)).to eq(expected_prompt)
      end
    end

    context "with a non-existent llm_prompt_name" do
      let(:llm_prompt_name) { "non_existent_llm_prompt_name" }

      it "raises an error" do
        expect {
          described_class.new(llm_prompt_name)
        }.to raise_error("No LLM prompts found for #{llm_prompt_name}")
      end
    end
  end
end
