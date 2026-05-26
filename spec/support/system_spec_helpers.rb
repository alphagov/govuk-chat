module SystemSpecHelpers
  def given_i_am_a_web_chat_user
    @signon_user = create(:signon_user, :web_chat)
    login_as(@signon_user)
  end

  def given_i_am_using_the_claude_structured_answer_strategy
    allow(Rails.configuration)
      .to receive(:answer_strategy)
      .and_return("claude_structured_answer")
  end

  def given_i_have_dismissed_the_cookie_banner
    visit homepage_path

    within(".gem-c-cookie-banner") do
      click_button "Reject additional cookies"
      click_button "Hide cookie message"
    end
  end
  alias_method :and_i_have_dismissed_the_cookie_banner, :given_i_have_dismissed_the_cookie_banner

  def set_rack_cookie(name, value)
    cookie_string = Rack::Utils.set_cookie_header(name, value)
    Capybara.current_session.driver.browser.set_cookie(cookie_string)
  end

  def given_i_am_an_admin
    login_as(create(:signon_user, :admin))
  end

  def given_i_am_an_admin_with_the_settings_permission
    login_as(create(:signon_user, :admin_area_settings))
  end

  def stubs_for_mock_answer(question,
                            answer,
                            rephrase_question: false,
                            sources_used: [],
                            create_content_chunk: true)
    stub_claude_jailbreak_guardrails(question)

    if rephrase_question
      rephrased_question = "Rephrased #{question}"

      stub_claude_question_rephrasing(question, rephrased_question)

      question = rephrased_question
    end

    stub_bedrock_titan_embedding(question)

    if create_content_chunk
      populate_chunked_content_index([
        build(:chunked_content_record, titan_embedding: mock_titan_embedding(question)),
      ])
    end

    stub_claude_question_routing(question)
    stub_claude_structured_answer(question, answer, sources_used:)

    stub_claude_output_guardrails(answer)
    stub_bedrock_invoke_model_openai_oss_topic_tagger(question)
    stub_bedrock_invoke_model_openai_oss_answer_relevancy(
      question_message: question,
      answer_message: answer,
    )

    retrieval_context = <<~STRING
      Title
      Heading 1 > Heading 2
      Description
      <p>Some content</p>
    STRING

    stub_bedrock_invoke_model_openai_oss_faithfulness(
      retrieval_context: retrieval_context,
      answer_message: answer,
    )
    stub_bedrock_invoke_model_openai_oss_coherence(
      question_message: question,
      answer_message: answer,
    )
    stub_bedrock_invoke_model_openai_oss_context_relevancy(
      question_message: question,
    )
  end
end
