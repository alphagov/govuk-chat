module LlmCallsRecordable
  extend ActiveSupport::Concern

  included do
    def assign_metrics(namespace, values)
      metrics[namespace] = values
    end

    def assign_llm_response(namespace, hash)
      llm_responses[namespace] = hash
    end
  end
end
