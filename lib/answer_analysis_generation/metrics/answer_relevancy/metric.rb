module AnswerAnalysisGeneration::Metrics::AnswerRelevancy
  class Metric
    Result = Data.define(
      :score,
      :reason,
      :success,
      :llm_responses,
      :metrics,
    )

    MODEL = "openai.gpt-oss-120b-1:0".freeze

    def self.call(...) = new(...).call

    def initialize(question_message:, answer_message:, threshold: 0.5)
      @question_message = question_message
      @answer_message = answer_message
      @threshold = threshold
    end

    def call
      statements_result = AnswerAnalysisGeneration::Metrics::AnswerRelevancy::StatementGenerator.new(
        answer_message:,
      ).call

      if statements_result.statements.empty?
        llm_responses = { answer_relevancy_statements: statements_result.llm_response }
        metrics = { answer_relevancy_statements: statements_result.metrics }
        return Result.new(
          score: 1.0,
          reason: "No statements were extracted from the answer.",
          success: true,
          llm_responses:,
          metrics:,
        )
      end

      verdicts_result = AnswerAnalysisGeneration::Metrics::AnswerRelevancy::VerdictsGenerator.new(
        question_message:, statements: statements_result.statements,
      ).call

      if verdicts_result.verdicts.empty?
        llm_responses = {
          answer_relevancy_statements: statements_result.llm_response,
          answer_relevancy_verdicts: verdicts_result.llm_response,
        }
        metrics = {
          answer_relevancy_statements: statements_result.metrics,
          answer_relevancy_verdicts: verdicts_result.metrics,
        }
        return Result.new(
          score: 1.0,
          reason: "No verdicts were generated for the extracted statements.",
          success: true,
          llm_responses:,
          metrics:,
        )
      end

      score = calculate_score(verdicts_result.verdicts)
      reason_result = AnswerAnalysisGeneration::Metrics::AnswerRelevancy::ReasonGenerator.new(
        question_message:, verdicts: verdicts_result.verdicts, score:,
      ).call

      llm_responses = {
        answer_relevancy_statements: statements_result.llm_response,
        answer_relevancy_verdicts: verdicts_result.llm_response,
        answer_relevancy_reason: reason_result.llm_response,
      }
      metrics = {
        answer_relevancy_statements: statements_result.metrics,
        answer_relevancy_verdicts: verdicts_result.metrics,
        answer_relevancy_reason: reason_result.metrics,
      }

      Result.new(
        score:,
        reason: reason_result.reason,
        success: is_successful?(score),
        llm_responses:,
        metrics:,
      )
    end

  private

    attr_reader :question_message, :answer_message, :threshold

    def calculate_score(verdicts)
      verdict_count = verdicts.count
      return 1.0 if verdict_count.zero?

      relevant_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase == "yes" }
      relevant_count.to_f / verdict_count
    end

    def is_successful?(score)
      score >= threshold
    end
  end
end
