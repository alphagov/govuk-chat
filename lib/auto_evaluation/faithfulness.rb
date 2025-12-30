class AutoEvaluation::Faithfulness
  THRESHOLD = 0.5

  def self.call(...) = new(...).call

  def initialize(answer_message:, retrieval_context:)
    @answer_message = answer_message
    @retrieval_context = retrieval_context
    @llm_responses = {}
    @metrics = {}
  end

  def call
    truths, llm_responses[:truths], metrics[:truths] = TruthsGenerator.call(retrieval_context:)

    claims, llm_responses[:claims], metrics[:claims] = ClaimsGenerator.call(answer_message:)

    if claims.empty?
      return build_maximum_score_result(
        reason: "No claims were extracted from the answer.",
        llm_responses:,
        metrics:,
      )
    end

    if truths.empty?
      return build_maximum_score_result(
        reason: "No truths were extracted from the retrieval context.",
        llm_responses:,
        metrics:,
      )
    end

    verdicts, llm_responses[:verdicts], metrics[:verdicts] = VerdictsGenerator.call(
      claims:, retrieval_context: truths.join("\n\n"),
    )

    if verdicts.empty?
      return build_maximum_score_result(
        reason: "No verdicts were generated for the extracted claims.",
        llm_responses:,
        metrics:,
      )
    end

    if verdicts.none? { |verdict| verdict["verdict"].strip.downcase == "no" }
      return build_maximum_score_result(
        reason: "All claims in the response are supported by the retrieval context.",
        llm_responses:,
        metrics:,
      )
    end

    score = calculate_score(verdicts)

    reason, llm_responses[:reason], metrics[:reason] = ReasonGenerator.call(
      score: sprintf("%.2f", score), verdicts:,
    )

    AutoEvaluation::Result.new(
      score:,
      reason:,
      success: score >= THRESHOLD,
      llm_responses:,
      metrics:,
    )
  end

private

  attr_reader :answer_message, :retrieval_context
  attr_accessor :llm_responses, :metrics

  def calculate_score(verdicts)
    verdict_count = verdicts.count
    return 1.0 if verdict_count.zero?

    faithful_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase != "no" }
    faithful_count.to_f / verdict_count
  end

  def build_maximum_score_result(reason:, llm_responses:, metrics:)
    AutoEvaluation::Result.new(
      score: 1.0,
      reason:,
      success: true,
      llm_responses:,
      metrics:,
    )
  end
end
