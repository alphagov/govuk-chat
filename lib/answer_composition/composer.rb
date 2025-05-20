module AnswerComposition
  class Composer
    delegate :answer_strategy, to: :question

    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
    end

    def call
      start_time = Clock.monotonic_time

      compose_answer.tap do |answer|
        ForbiddenTermsChecker.call(answer)
        answer.assign_metrics("answer_composition", build_metrics(start_time))
      end
    rescue StandardError => e
      GovukError.notify(e)
      answer = question.answer || question.build_answer

      answer.assign_attributes(
        message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
        status: "error_non_specific",
        error_message: "class: #{e.class} message: #{e.message}",
      )
      answer.set_sources_as_unused
      answer.assign_metrics("answer_composition", build_metrics(start_time))
      answer
    end

  private

    attr_reader :question

    def compose_answer
      case answer_strategy
      when "openai_structured_answer"
        PipelineRunner.call(question:, pipeline: [
          Pipeline::JailbreakGuardrails.new(llm_provider: :openai),
          Pipeline::QuestionRephraser.new(llm_provider: :openai),
          Pipeline::OpenAI::QuestionRouter,
          Pipeline::QuestionRoutingGuardrails.new(llm_provider: :openai),
          Pipeline::SearchResultFetcher,
          Pipeline::OpenAI::StructuredAnswerComposer,
          Pipeline::AnswerGuardrails.new(llm_provider: :openai),
        ])
      when "claude_structured_answer"
        PipelineRunner.call(question:, pipeline: [
          Pipeline::JailbreakGuardrails.new(llm_provider: :claude),
          Pipeline::QuestionRephraser.new(llm_provider: :claude),
          Pipeline::Claude::QuestionRouter,
          Pipeline::QuestionRoutingGuardrails.new(llm_provider: :claude),
          Pipeline::SearchResultFetcher,
          Pipeline::Claude::StructuredAnswerComposer,
          Pipeline::AnswerGuardrails.new(llm_provider: :claude),
        ])
      else
        raise "Answer strategy #{answer_strategy} not configured"
      end
    end

    def build_metrics(start_time)
      { duration: Clock.monotonic_time - start_time }
    end
  end
end
