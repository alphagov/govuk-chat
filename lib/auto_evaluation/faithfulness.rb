class AutoEvaluation::Faithfulness
  THRESHOLD = 0.5

  def self.call(...) = new(...).call

  def initialize(answer)
    @answer = answer
    @llm_responses = {}
    @metrics = {}
  end

  def call
    truths, llm_responses[:truths], metrics[:truths] = TruthsGenerator.call(retrieval_context:)

    if truths.empty?
      return build_maximum_score_result(
        reason: "No truths were extracted from the retrieval context.",
        llm_responses:,
        metrics:,
      )
    end

    claims, llm_responses[:claims], metrics[:claims] = ClaimsGenerator.call(answer_message:)

    if claims.empty?
      return build_maximum_score_result(
        reason: "No claims were extracted from the answer.",
        llm_responses:,
        metrics:,
      )
    end

    verdicts, llm_responses[:verdicts], metrics[:verdicts] = VerdictsGenerator.call(
      claims:, truths:,
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
        reason: "The response is fully supported by the retrieval context.",
        llm_responses:,
        metrics:,
      )
    end

    score = calculate_score(verdicts)

    reason, llm_responses[:reason], metrics[:reason] = ReasonGenerator.call(
      score: score.round(2), verdicts:,
    )

    AutoEvaluation::ScoreResult.new(
      score:,
      reason:,
      success: score >= THRESHOLD,
      llm_responses:,
      metrics:,
    )
  end

private

  attr_reader :answer
  attr_accessor :llm_responses, :metrics

  def answer_message
    answer.message
  end

  def retrieval_context
    used_sources.map(&:plain_content).join("\n\n")
  end

  def calculate_score(verdicts)
    return 1.0 if verdicts.empty?

    faithful_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase != "no" }
    faithful_count.to_d / verdicts.count
  end

  def used_sources
    answer.sources.used
  end

  def build_maximum_score_result(reason:, llm_responses:, metrics:)
    AutoEvaluation::ScoreResult.new(
      score: 1.0,
      reason:,
      success: true,
      llm_responses:,
      metrics:,
    )
  end
end
