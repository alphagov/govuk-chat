class AutoEvaluation::ContextRelevancy
  THRESHOLD = 0.8

  def self.call(...) = new(...).call

  def initialize(answer)
    @answer = answer
    @llm_responses = {}
    @metrics = {}
  end

  def call
    if used_sources.empty?
      return build_maximum_score_result("No sources were retrieved when generating the answer.")
    end

    information_needs, llm_responses[:information_needs], metrics[:information_needs] = InformationNeedsGenerator.call(
      question: answer.question_used,
    )

    if information_needs.empty?
      return build_maximum_score_result("No information needs were generated.")
    end

    truths, llm_responses[:truths], metrics[:truths] = TruthsGenerator.call(
      answer_sources: used_sources,
    )

    if truths.empty?
      return build_maximum_score_result("No truths were generated.")
    end

    verdicts, llm_responses[:verdicts], metrics[:verdicts] = VerdictsGenerator.call(
      truths:,
      information_needs:,
    )

    if verdicts.empty?
      return build_maximum_score_result("No verdicts were generated.")
    end

    score = calculate_score(verdicts)

    reason, llm_responses[:reason], metrics[:reason] = ReasonGenerator.call(
      score: score.round(2),
      question_message: answer.question_used,
      verdicts:,
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

  def calculate_score(verdicts)
    verdicts_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase != "no" }
    verdicts_count.to_d / verdicts.count
  end

  def used_sources
    answer.sources.select(&:used)
  end

  def build_maximum_score_result(reason)
    AutoEvaluation::ScoreResult.new(
      score: 1.0,
      reason:,
      success: true,
      llm_responses:,
      metrics:,
    )
  end
end
