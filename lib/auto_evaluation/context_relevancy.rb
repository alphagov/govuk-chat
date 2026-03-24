class AutoEvaluation::ContextRelevancy
  THRESHOLD = 0.8

  def self.call(...) = new(...).call

  def initialize(answer)
    @answer = answer
    @llm_responses = {}
    @metrics = {}
  end

  def call
    return build_error_result("No sources were retrieved when generating the answer.") if answer.sources.empty?

    information_needs, llm_responses[:information_needs], metrics[:information_needs] = InformationNeedsGenerator.call(
      question: answer.question_used,
    )

    return build_error_result("No information needs were generated.") if information_needs.empty?

    truths, llm_responses[:truths], metrics[:truths] = TruthsGenerator.call(
      answer_sources: answer.sources,
    )

    return build_error_result("No truths were generated.") if truths.empty?

    verdicts, llm_responses[:verdicts], metrics[:verdicts] = VerdictsGenerator.call(
      truths:,
      information_needs:,
    )

    return build_error_result("No verdicts were generated.") if verdicts.empty?

    score = calculate_score(verdicts)

    reason, llm_responses[:reason], metrics[:reason] = ReasonGenerator.call(
      score: score.round(2),
      question_message: answer.question_used,
      verdicts:,
    )

    AutoEvaluation::Result.new(
      status: score >= THRESHOLD ? "success" : "failure",
      score:,
      reason:,
      llm_responses:,
      metrics:,
    )
  rescue AutoEvaluation::BedrockOpenAIOssInvoke::InvalidLlmResponseError => e
    build_error_result(e.message)
  end

private

  attr_reader :answer
  attr_accessor :llm_responses, :metrics

  def calculate_score(verdicts)
    verdicts_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase != "no" }
    verdicts_count.to_d / verdicts.count
  end

  def build_error_result(error_message)
    AutoEvaluation::Result.new(
      status: "error",
      error_message:,
      llm_responses:,
      metrics:,
    )
  end
end
