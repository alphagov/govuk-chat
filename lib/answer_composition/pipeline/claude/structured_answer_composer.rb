module AnswerComposition::Pipeline::Claude
  class StructuredAnswerComposer
    BEDROCK_MODEL = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0".freeze

    def self.call(...) = new(...).call

    def initialize(context)
      @context = context
    end

    def call
      start_time = Clock.monotonic_time

      response = bedrock_client.converse(
        system: [{ text: system_prompt }],
        model_id: BEDROCK_MODEL,
        messages:,
        inference_config:,
        tool_config:,
      )

      context.answer.assign_llm_response("structured_answer", response.to_h)
      message = response.dig("output", "message", "content", 0, "tool_use", "input", "answer")
      context.answer.assign_attributes(message:, status: "answered")
      context.answer.assign_metrics("structured_answer", build_metrics(start_time, response))
    end

  private

    attr_reader :context

    def messages
      [
        {
          role: "user",
          content: [{ text: context.question_message }],
        },
      ]
    end

    def inference_config
      {
        max_tokens: 1000,
        temperature: 0.0,
      }
    end

    def system_prompt
      <<~PROMPT
        You are a chat assistant for the UK government, designed to provide helpful and contextually relevant responses to user queries.
        Provide concise responses based on the content on the GOV.UK website.
      PROMPT
    end

    def bedrock_client
      @bedrock_client ||= Aws::BedrockRuntime::Client.new
    end

    def build_metrics(start_time, response)
      {
        duration: Clock.monotonic_time - start_time,
        llm_prompt_tokens: response.dig("usage", "input_tokens"),
        llm_completion_tokens: response.dig("usage", "output_tokens"),
      }
    end

    def tool_config
      {
        tools: tools,
        tool_choice: {
          tool: {
            name: "answer_confidence",
          },
        },
      }
    end

    def tools
      [
        {
          tool_spec: {
            name: "answer_confidence",
            description: "Prints the answer of a given question with a confidence score.",
            input_schema: {
              json: {
                type: "object",
                properties: {
                  answer: { description: "Your answer to the question in markdown format", title: "Answer", type: "string" },
                  confidence: { description: "Your confidence in the answer provided, ranging from 0.0 to 1.0", title: "Confidence", type: "number" },
                },
                required: %w[answer confidence],
              },
            },
          },
        },
      ]
    end
  end
end
