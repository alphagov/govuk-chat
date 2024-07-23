module AnswerComposition
  class OpenAIAnswer
    def self.call(...) = new(...).call

    def initialize(question:, pipeline: [])
      @context = Pipeline::Context.new(question)
      @pipeline = pipeline
    end

    def call
      catch :abort do
        pipeline.each do |pipeline_step|
          pipeline_step.call(context)
          break if context.aborted?
        end
      end

      context.answer
    rescue OpenAIClient::ContextLengthExceededError => e
      GovukError.notify(e)
      context.abort_pipeline(
        message: Answer::CannedResponses::CONTEXT_LENGTH_EXCEEDED_RESPONSE,
        status: "error_context_length_exceeded",
        error_message: error_message(e),
      )
    rescue OpenAIClient::RequestError => e
      GovukError.notify(e)
      context.abort_pipeline(
        message: Answer::CannedResponses::OPENAI_CLIENT_ERROR_RESPONSE,
        status: "error_answer_service_error",
        error_message: error_message(e),
      )
    end

  private

    attr_reader :context, :pipeline

    def error_message(error)
      body_error_message = if error.response
                             error.response[:body]&.dig("error", "message")
                           end

      "class: #{error.class} message: #{body_error_message || error.message}"
    end
  end
end
