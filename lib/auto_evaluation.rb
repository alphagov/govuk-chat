module AutoEvaluation
  ScoreResult = Data.define(
    :score,
    :reason,
    :success,
    :llm_responses,
    :metrics,
  )
end
