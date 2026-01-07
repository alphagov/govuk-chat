module AutoEvaluation
  class ContextRelevancy::TruthsGenerator
    def self.call(...) = new(...).call

    def initialize(answer_sources:)
      @answer_sources = answer_sources
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_prompt, tools)
      [result.evaluation_data.fetch("truths"), result.llm_response, result.metrics]
    end

  private

    attr_reader :answer_sources

    def llm_prompts
      Prompts.config.context_relevancy.fetch(:truths)
    end

    def user_prompt
      sprintf(
        llm_prompts.fetch(:user_prompt),
        retrieval_context: retrieval_context.join("\n\n"),
      )
    end

    def tools
      [llm_prompts.fetch(:tool_spec)]
    end

    def retrieval_context
      answer_sources.map do |source|
        <<~CONTEXT
          # Context
          Page title: #{source.title}
          Description: #{source.description}
          Headings: #{source.heading_hierarchy.join(' > ')}
          # Content
          #{Nokogiri::HTML(source.html_content).text}
        CONTEXT
      end
    end
  end
end
