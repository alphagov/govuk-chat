module AutoEvaluation
  class RequestTypeTagger
    Result = Data.define(
      :status,
      :primary_request_type,
      :secondary_request_type,
      :confidence,
      :reasoning,
      :metrics,
      :llm_response,
      :error_message,
    ) do
      def initialize(status:,
                     primary_request_type:,
                     secondary_request_type:,
                     confidence:,
                     reasoning:,
                     metrics:,
                     llm_response:,
                     error_message: nil)
        super
      end
    end

    def self.call(...) = new(...).call

    def initialize(user_question)
      @user_question = user_question
    end

    def call
      result = BedrockOpenAIOssInvoke.call(user_message: user_question, tool:, system_prompt:)
      Result.new(
        status: "success",
        primary_request_type: result.evaluation_data.fetch("primary_label").downcase,
        secondary_request_type: result.evaluation_data.fetch("secondary_label")&.downcase,
        confidence: result.evaluation_data.fetch("confidence"),
        reasoning: result.evaluation_data.fetch("reasoning"),
        metrics: result.metrics,
        llm_response: result.llm_response,
      )
    rescue AutoEvaluation::BedrockOpenAIOssInvoke::InvalidLlmResponseError => e
      Result.new(
        status: "error",
        primary_request_type: nil,
        secondary_request_type: nil,
        confidence: nil,
        reasoning: nil,
        metrics: {},
        llm_response: {},
        error_message: e.message,
      )
    end

  private

    attr_reader :user_question

    def request_type_config
      Prompts.config.request_type
    end

    def system_prompt
      request_type_config.fetch("system_prompt")
    end

    def tool
      request_type_config.fetch("tool_spec")
    end
  end
end
