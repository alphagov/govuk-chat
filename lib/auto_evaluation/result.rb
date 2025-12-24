module AutoEvaluation
  Result = Data.define(
    :score,
    :reason,
    :success,
    :llm_responses,
    :metrics,
  )
end
