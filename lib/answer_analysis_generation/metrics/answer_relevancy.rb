module AnswerAnalysisGeneration::Metrics
  class AnswerRelevancy
    # We would also want to return the llm responses and metrics, but i'm
    # not going to worry about it as part of this spike.
    Result = Data.define(
      :score,
      :reason,
      :success,
    )

    MODEL = "openai.gpt-oss-120b-1:0".freeze

    def self.call(...) = new(...).call

    def initialize(question_message:, answer_message:, strict_mode: false, threshold: 0.5)
      @question_message = question_message
      @answer_message = answer_message
      @strict_mode = strict_mode
      @threshold = strict_mode ? 1.0 : threshold
    end

    def call
      Result.new(
        score: calculate_score,
        reason:,
        success: is_successful?,
      )
    end

  private

    attr_reader :question_message, :answer_message, :threshold, :strict_mode

    def bedrock_client
      @bedrock_client ||= Aws::BedrockRuntime::Client.new
    end

    def llm_prompts
      Rails.configuration.govuk_chat_private.llm_prompts.auto_evaluation.answer_relevancy
    end

    def statements
      @statements ||= begin
        unparsed_statements = bedrock_client.converse(
          model_id: MODEL,
          messages: [{ "role": "user", "content": [{ "text": statements_system_prompt }] }],
          inference_config:,
        )
        parse_first_text_content(unparsed_statements)["statements"]
      end
    end

    def statements_system_prompt
      sprintf(
        llm_prompts["statements"]["system_prompt"],
        answer: answer_message,
      )
    end

    def inference_config
      {
        max_tokens: 4096,
        temperature: 0.0,
      }
    end

    def parse_first_text_content(bedrock_response)
      first_text_content_block = bedrock_response.output.message.content.detect do |content_block|
        content_block.is_a?(Aws::BedrockRuntime::Types::ContentBlock::Text)
      end

      JSON.parse(first_text_content_block.text)
    end

    def verdicts
      @verdicts ||= begin
        verdicts_response = bedrock_client.converse(
          model_id: MODEL,
          messages: [{ "role": "user", "content": [{ "text": verdicts_system_prompt }] }],
          inference_config:,
        )
        parse_first_text_content(verdicts_response)["verdicts"]
      end
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

    def reason
      @reason ||= begin
        reasons_response = bedrock_client.converse(
          model_id: MODEL,
          messages: [{ "role": "user", "content": [{ "text": reason_system_prompt }] }],
          inference_config:,
        )

        parse_first_text_content(reasons_response)["reason"]
      end
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
