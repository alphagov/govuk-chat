module AnswerComposition::MultipleGuardrail
  class Prompt
    Guardrail = Data.define(:key, :name, :content)

    def self.collated(llm_prompt_name)
      prompt = Prompt.new(llm_prompt_name)

      <<~PROMPT
        # System prompt

        #{prompt.system_prompt}
        # User prompt

        #{prompt.user_prompt('<insert answer to check>')}
      PROMPT
    end

    def initialize(prompt_name)
      prompts = AnswerComposition::Pipeline::Prompts.config(
        prompt_name, Checker.bedrock_model
      )

      raise "No LLM prompts found for #{prompt_name}" unless prompts

      @prompts = prompts
    end

    def system_prompt
      guardrails_content = guardrails.map { |g| "#{g.key}. #{g.content}" }
                                     .join("\n")

      prompts.fetch(:system_prompt)
             .sub("{guardrails}", guardrails_content)
             .sub("{date}", Date.current.strftime("%A %d %B %Y"))
    end

    def user_prompt(input)
      prompts.fetch(:user_prompt).sub("{input}", input)
    end

    def guardrails
      @guardrails ||= prompts.fetch(:guardrails).map.with_index(1) do |name, key|
        content = prompts.fetch(:guardrail_definitions).fetch(name)
        Guardrail.new(key:, name:, content:)
      end
    end

  private

    attr_reader :prompts
  end
end
