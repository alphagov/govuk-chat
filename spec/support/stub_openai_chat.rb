module StubOpenAIChat
  def stub_openai_chat_completion(
    question_or_history,
    answer: nil,
    chat_options: {},
    tool_calls: nil,
    finish_reason: "stop"
  )
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
        body: openai_chat_completion_response_body(answer:, tool_calls:, finish_reason:),
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
              name: "generate_answer_using_retrieved_contexts",
              description: "Use the provided contexts to generate an answer to the question.",
              strict: true,
              parameters: output_schema,
            },
          },
        ],
        tool_choice: "required",
        parallel_tool_calls: false,
      },
    )

    tool_calls = [openai_chat_completion_tool_call("generate_answer_using_retrieved_contexts", answer)]

    stub_openai_chat_completion(question_or_history, chat_options: structured_generation_chat_options, tool_calls:)
  end

  def stub_openai_chat_question_routing(
    question_or_history,
    tools: an_instance_of(Array),
    function_name: "genuine_rag",
    function_arguments: { "answer": "This is RAG.", confidence: 1.0 },
    finish_reason: "stop"
  )
    function_arguments = function_arguments.to_json unless function_arguments.is_a?(String)

    chat_options = {
      model: AnswerComposition::Pipeline::QuestionRouter::OPENAI_MODEL,
      tools:,
      tool_choice: "required",
      max_completion_tokens: AnswerComposition::Pipeline::QuestionRouter::MAX_COMPLETION_TOKENS,
    }

    stub_openai_chat_completion(
      question_or_history,
      chat_options:,
      tool_calls: [openai_chat_completion_tool_call(function_name, function_arguments)],
      finish_reason:,
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

  def stub_openai_output_guardrail(to_check, response = "False | None")
    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => a_string_including(to_check) }),
      answer: response,
      chat_options: { model: OutputGuardrails::FewShot::OPENAI_MODEL },
    )
  end

  def stub_openai_jailbreak_guardrails(to_check, response = InputGuardrails::Jailbreak.pass_value)
    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => a_string_including(to_check) }),
      answer: response,
      chat_options: { model: InputGuardrails::Jailbreak::OPENAI_MODEL,
                      max_tokens: InputGuardrails::Jailbreak.max_tokens,
                      logit_bias: InputGuardrails::Jailbreak.logit_bias },
    )
  end

  def openai_chat_completion_response_body(answer: nil, tool_calls: nil, finish_reason: "stop")
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
          finish_reason:,
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

  def hash_including_openai_response_with_tool_call(tool_call_name)
    a_hash_including(
      "finish_reason" => "stop",
      "message" => a_hash_including(
        "role" => "assistant",
        "tool_calls" => an_array_matching(
          a_hash_including(
            "function" => a_hash_including(
              "name" => tool_call_name,
            ),
          ),
        ),
      ),
    )
  end
end
