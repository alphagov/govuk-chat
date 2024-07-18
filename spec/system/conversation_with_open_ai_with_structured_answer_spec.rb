RSpec.describe "Conversation with OpenAI with a structured answer", :chunked_content_index do
  include ActiveJob::TestHelper

  scenario do
    given_the_structured_answer_generation_feature_flag_is_active
    and_i_have_confirmed_i_understand_chat_risks
    when_i_visit_the_conversation_page
    and_i_enter_a_question
    then_i_see_the_answer_is_pending

    when_the_first_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_question_on_the_page
    and_i_can_see_the_first_answer

    when_i_enter_a_second_question
    then_i_see_the_answer_is_pending

    when_the_second_answer_is_generated
    and_i_click_on_the_check_answer_button
    then_i_see_my_second_question_on_the_page
    and_i_can_see_the_second_answer
  end

  def given_the_structured_answer_generation_feature_flag_is_active
    Flipper.enable(:structured_answer_generation)
  end

  def when_i_visit_the_conversation_page
    visit show_conversation_path
  end

  def and_i_enter_a_question
    fill_in "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)", with: "How much tax should I be paying?"
    click_on "Send"
  end

  def then_i_see_the_answer_is_pending
    expect(page).to have_content("GOV.UK Chat is generating an answer")
  end

  def when_the_first_answer_is_generated
    @openai_embedding = mock_openai_embedding("How much tax should i pay?")
    allow(Search::TextToEmbedding)
    .to receive(:call)
    .and_return(@openai_embedding)
    populate_chunked_content_index([
      build(:chunked_content_record, openai_embedding: @openai_embedding, exact_path: "/pay-more-tax#yes-really"),
    ])
    stub_openai_chat_completion_structured_response(
      array_including({ "role" => "user", "content" => "How much tax should I be paying?" }),
      {
        answer: "Lots of tax.",
        answered: true,
        call_for_action: "For more detailed information, you can visit [Pay more tax](https://www.gov.uk/pay-more-tax)",
        sources_used: ["/pay-more-tax#yes-really"],
      }.to_json,
    )
    stub_openai_output_guardrail_pass("Lots of tax.\n\nFor more detailed information, you can visit [Pay more tax](https://www.gov.uk/pay-more-tax)")

    perform_enqueued_jobs
  end

  def when_the_second_answer_is_generated
    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => "Are you sure?" }),
      "Rephrased How much tax should I be paying?",
    )
    stub_openai_chat_completion_structured_response(
      array_including({ "role" => "user", "content" => "Rephrased How much tax should I be paying?" }),
      {
        answer: "Even more tax.",
        answered: true,
        call_for_action: "For more detailed information, you can visit [Pay more tax](https://www.gov.uk/pay-more-tax)",
        sources_used: ["/pay-more-tax#yes-really"],
      }.to_json,
    )
    stub_openai_output_guardrail_pass("Even more tax.\n\nFor more detailed information, you can visit [Pay more tax](https://www.gov.uk/pay-more-tax)")

    perform_enqueued_jobs
  end

  def and_i_click_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_i_see_my_question_on_the_page
    expect(page).to have_content("How much tax should I be paying?")
  end

  def and_i_can_see_the_first_answer
    expect(page).to have_content("Lots of tax.\nFor more detailed information, you can visit Pay more tax")
  end

  def and_i_can_see_the_second_answer
    expect(page).to have_content("Even more tax.\nFor more detailed information, you can visit Pay more tax")
  end

  def when_i_enter_a_second_question
    fill_in "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)", with: "Are you sure?"
    click_on "Send"
  end

  def then_i_see_my_second_question_on_the_page
    expect(page).to have_content("Are you sure?")
  end
end
