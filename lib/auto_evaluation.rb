module AutoEvaluation
  ScoreResult = Data.define(
    :score,
    :reason,
    :llm_responses,
    :metrics,
  )
end
