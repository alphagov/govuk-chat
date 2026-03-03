module AutoEvaluation
  Result = Data.define(
    :status,
    :score,
    :reason,
    :error_message,
    :llm_responses,
    :metrics,
  ) do
    def initialize(
      status:,
      llm_responses:,
      metrics:,
      score: nil,
      reason: nil,
      error_message: nil
    )
      super
    end
  end
end
