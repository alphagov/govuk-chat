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

    return build_error_result("No truths were extracted from the retrieval context.") if truths.empty?

    claims, llm_responses[:claims], metrics[:claims] = ClaimsGenerator.call(answer_message:)

    return build_error_result("No claims were extracted from the answer.") if claims.empty?

    verdicts, llm_responses[:verdicts], metrics[:verdicts] = VerdictsGenerator.call(
      claims:, truths:,
    )

    return build_error_result("No verdicts were generated for the extracted claims.") if verdicts.empty?

    if verdicts.all? { |verdict| verdict["verdict"].strip.downcase == "yes" }
      return build_result_with_score(1.0, "The response is fully supported by the retrieval context.")
    end

    score = calculate_score(verdicts)

    reason, llm_responses[:reason], metrics[:reason] = ReasonGenerator.call(
      score: score.round(2), verdicts:,
    )

    build_result_with_score(score, reason)
  rescue AutoEvaluation::BedrockOpenAIOssInvoke::InvalidLlmResponseError => e
    build_error_result(e.message)
  end

private

  attr_reader :answer
  attr_accessor :llm_responses, :metrics

  def answer_message
    answer.message
  end

  def retrieval_context
    answer.sources.map { |source| format_chunk_for_evaluation(source.chunk) }.join("\n")
  end

  def calculate_score(verdicts)
    faithful_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase == "yes" }
    faithful_count.to_d / verdicts.count
  end

  def build_error_result(error_message)
    AutoEvaluation::Result.new(
      status: "error",
      error_message:,
      llm_responses:,
      metrics:,
    )
  end

  def build_result_with_score(score, reason)
    AutoEvaluation::Result.new(
      status: score >= THRESHOLD ? "success" : "failure",
      score:,
      reason:,
      llm_responses:,
      metrics:,
    )
  end

  def format_chunk_for_evaluation(chunk)
    <<~STRING
      #{chunk.title}
      #{chunk.heading_hierarchy.join(' > ')}
      #{chunk.description}
      #{chunk.html_content}
    STRING
  end
end
