module StubOpenAIChat
  def stub_openai_chat_completion(question_or_history, answer: nil, chat_options: {}, tool_calls: nil)
    history = if question_or_history.is_a?(String)
                array_including({ "role" => "user", "content" => question_or_history })
              else
                question_or_history
              end

    request_body = hash_including(
      {
        "model" => /^gpt/,
        "messages" => history,
        "temperature" => 0.0,
      }.merge(chat_options),
    )

    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{Rails.configuration.openai_access_token}",
        },
        body: request_body,
      )
      .to_return_json(
        status: 200,
        body: openai_chat_completion_response_body(answer:, tool_calls:),
        headers: {},
      )
  end

  def stub_openai_chat_completion_structured_response(question_or_history, answer, chat_options: {})
    output_schema = Rails.configuration.llm_prompts.openai_structured_answer[:output_schema]

    structured_generation_chat_options = chat_options.merge(
      {
        model: AnswerComposition::Pipeline::OpenAIStructuredAnswerComposer::OPENAI_MODEL,
        tools: [
          {
            type: "function",
            function: {
              "name": "generate_answer_using_retrieved_contexts",
              "description": "Use the provided contexts to generate an answer to the question.",
              "parameters": {
                "type": output_schema[:type],
                "properties": output_schema[:properties],
              },
              "required": output_schema[:required],
            },
          },
        ],
        tool_choice: "required",
      },
    )

    tool_calls = [openai_chat_completion_tool_call("generate_answer_using_retrieved_contexts", answer)]

    stub_openai_chat_completion(question_or_history, chat_options: structured_generation_chat_options, tool_calls:)
  end

  def stub_openai_chat_question_routing(question_or_history, tools: an_instance_of(Array), function_name: "genuine_rag", function_arguments: {})
    function_arguments = function_arguments.to_json unless function_arguments.is_a?(String)

    chat_options = {
      model: AnswerComposition::Pipeline::QuestionRouter::OPENAI_MODEL,
      tools:,
      tool_choice: "required",
    }

    stub_openai_chat_completion(
      question_or_history,
      chat_options:,
      tool_calls: [openai_chat_completion_tool_call(function_name, function_arguments)],
    )
  end

  def stub_openai_chat_completion_error(status: 400, type: "invalid_request_error", code: nil)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return_json(
        status:,
        body: {
          error: {
            message: "Error message",
            type:,
            param: nil,
            code:,
          },
        },
        headers: {},
      )
  end

  def stub_openai_question_rephrasing(original_question, rephrased_question)
    config = Rails.configuration.llm_prompts.question_rephraser

    stub_openai_chat_completion(
      array_including(
        { "role" => "system", "content" => config[:system_prompt] },
        { "role" => "user", "content" => a_string_including(original_question) },
      ),
      answer: rephrased_question,
    )
  end

  def stub_openai_output_guardrail_pass(answer)
    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => a_string_including(answer) }),
      answer: "False | None",
      chat_options: { model: OutputGuardrails::FewShot::OPENAI_MODEL,
                      max_tokens: OutputGuardrails::FewShot::OPENAI_MAX_TOKENS },
    )
  end

  def openai_chat_completion_response_body(answer: nil, tool_calls: nil)
    {
      id: "chatcmpl-abc123",
      object: "chat.completion",
      created: 1_677_858_242,
      model: "gpt-4o-mini-2024-07-18",
      usage: {
        prompt_tokens: 13,
        completion_tokens: 7,
        total_tokens: 20,
      },
      choices: [
        {
          message: {
            role: "assistant",
            content: answer,
          },
          logprobs: nil,
          finish_reason: "stop",
          index: 0,
        },
      ],
    }.tap do |body|
      next unless tool_calls

      body.dig(:choices, 0, :message).merge!(tool_calls:)
    end
  end

  def openai_chat_completion_tool_call(name, arguments)
    {
      id: "call_#{SecureRandom.hex(12)}",
      type: "function",
      function: {
        name:,
        arguments:,
      },
    }
  end
end
