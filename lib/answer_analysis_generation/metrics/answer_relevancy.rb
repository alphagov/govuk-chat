module AnswerAnalysisGeneration::Metrics
  class AnswerRelevancy
    # We would also want to return the llm responses and metrics, but i'm
    # not going to worry about it as part of this spike.
    Result = Data.define(
      :score,
      :reason,
      :success,
      :llm_responses,
    )

    MODEL = "openai.gpt-oss-120b-1:0".freeze

    def self.call(...) = new(...).call

    def initialize(question_message:, answer_message:, threshold: 0.5)
      @question_message = question_message
      @answer_message = answer_message
      @threshold = threshold
    end

    def call
      Result.new(
        score: calculate_score,
        reason:,
        success: is_successful?,
        llm_responses: {
          answer_relevancy_statements: statements_response.to_h,
          answer_relevancy_verdicts: verdicts_response.to_h,
          answer_relevancy_reason: reason_response.to_h,
        },
      )
    end

  private

    attr_reader :question_message, :answer_message, :threshold

    def llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy
    end

    def statements_response
      @statements_response ||= BedrockConverseClient.call(
        messages: [{ "role": "user", "content": [{ "text": statements_system_prompt }] }],
      )
    end

    def statements
      BedrockConverseClient.parse_first_text_content_from_response(statements_response)["statements"]
    end

    def statements_system_prompt
      sprintf(
        llm_prompts["statements"]["system_prompt"],
        answer: answer_message,
      )
    end

    def verdicts_response
      @verdicts_response ||= BedrockConverseClient.call(
        messages: [{ "role": "user", "content": [{ "text": verdicts_system_prompt }] }],
      )
    end

    def verdicts
      BedrockConverseClient.parse_first_text_content_from_response(verdicts_response)["verdicts"]
    end

    def verdicts_system_prompt
      sprintf(
        llm_prompts["verdicts"]["system_prompt"],
        question: question_message,
        statements: statements,
      )
    end

    def calculate_score
      @calculate_score ||= begin
        verdict_count = verdicts.count
        return 1.0 if verdict_count.zero?

        relevant_count = verdicts.count { |verdict| verdict["verdict"].strip.downcase != "no" }
        relevant_count.to_f / verdicts.count
      end
    end

    def reason_response
      @reason_response ||= BedrockConverseClient.call(
        messages: [{ "role": "user", "content": [{ "text": reason_system_prompt }] }],
      )
    end

    def reason
      BedrockConverseClient.parse_first_text_content_from_response(reason_response)["reason"]
    end

    def reason_system_prompt
      sprintf(
        llm_prompts["reason"]["system_prompt"],
        score: calculate_score,
        irrelevant_statements:,
        question: question_message,
      )
    end

    def irrelevant_statements
      verdicts.select { |statement| statement["verdict"].strip.downcase == "no" }
              .map { |verdict| verdict["reason"] }
    end

    def is_successful?
      calculate_score >= threshold
    end
  end
end
