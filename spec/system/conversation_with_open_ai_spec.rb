RSpec.describe "Conversation with OpenAI", :chunked_content_index do
  before do
    stub_text_to_embedding
    populate_opensearch
  end

  scenario do
    given_the_unstructured_answer_generation_feature_flag_is_active
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

  def given_the_unstructured_answer_generation_feature_flag_is_active
    Flipper.enable(:unstructured_answer_generation)
  end

  def stub_text_to_embedding
    @openai_embedding = mock_openai_embedding("How much tax should i pay?")
    allow(Search::TextToEmbedding)
    .to receive(:call)
    .and_return(@openai_embedding)
  end

  def populate_opensearch
    populate_chunked_content_index([
      build(:chunked_content_record, openai_embedding: @openai_embedding),
    ])
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
    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => "How much tax should I be paying?" }),
      "First answer from OpenAI",
    )
    stub_openai_output_guardrail_pass("First answer from OpenAI")
    execute_queued_sidekiq_jobs
  end

  def when_the_second_answer_is_generated
    rephrased = "Rephrased How much tax should I be paying?"

    stub_openai_question_rephrasing("Are you sure?", rephrased)

    stub_openai_chat_completion(
      array_including({ "role" => "user", "content" => rephrased }),
      "Second answer from OpenAI",
    )
    stub_openai_output_guardrail_pass("Second answer from OpenAI")
    execute_queued_sidekiq_jobs
  end

  def and_i_click_on_the_check_answer_button
    click_on "Check if an answer has been generated"
  end

  def then_i_see_my_question_on_the_page
    expect(page).to have_content("How much tax should I be paying?")
  end

  def and_i_can_see_the_first_answer
    expect(page).to have_content("First answer from OpenAI")
  end

  def and_i_can_see_the_second_answer
    expect(page).to have_content("Second answer from OpenAI")
  end

  def when_i_enter_a_second_question
    fill_in "Enter your question (please do not share personal or sensitive information in your conversations with GOV UK chat)", with: "Are you sure?"
    click_on "Send"
  end

  def then_i_see_my_second_question_on_the_page
    expect(page).to have_content("Are you sure?")
  end
end
