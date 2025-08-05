module LlmCallsRecordable
  extend ActiveSupport::Concern

  included do
    def assign_metrics(namespace, values)
      self.metrics ||= {}
      self.metrics[namespace] = values
    end

    def assign_llm_response(namespace, hash)
      self.llm_responses ||= {}
      self.llm_responses[namespace] = hash
    end
  end
end
