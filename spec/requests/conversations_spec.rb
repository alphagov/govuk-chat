RSpec.describe "ConversationsController" do
  include ActiveJob::TestHelper

  delegate :helpers, to: ConversationsController

  describe "GET :new" do
    it "renders the correct fields" do
      get new_conversation_path

      assert_response :success
      renders_the_create_question_form
    end
  end

  describe "POST :create" do
    it "saves the question and renders pending page with valid params" do
      post create_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }

      assert_response :redirect
      follow_redirect!
      assert_select ".govuk-notification-banner__heading", text: "GOV.UK Chat is generating an answer"
    end

    it "renders the new conversation page with an error when the params are invalid" do
      post create_conversation_path, params: { create_question: { user_question: "" } }

      assert_response :unprocessable_entity
      assert_select ".govuk-error-summary a[href='#create_question_user_question']", text: "Enter a question"
      renders_the_create_question_form
    end
  end

  describe "GET :show" do
    it "renders the question form" do
      question = create(:question, :with_answer)
      get show_conversation_path(question.conversation)

      assert_response :success
      renders_the_create_question_form
    end

    context "when the conversation has a question with an answer" do
      it "renders the question and the answer" do
        question = create(:question, :with_answer)
        answer = question.answer

        get show_conversation_path(question.conversation)

        assert_response :success
        assert_select "##{helpers.dom_id(question)}", text: /#{question.message}/
        assert_select "##{helpers.dom_id(answer)}", text: /#{answer.message}/
      end
    end

    context "when the conversation has an unanswered question" do
      it "only renders a question" do
        question = create(:question)
        get show_conversation_path(question.conversation)

        assert_response :success
        assert_select "##{helpers.dom_id(question)}", text: /#{question.message}/
      end
    end
  end

  describe "PATCH :update" do
    let(:conversation) { create(:conversation) }

    it "saves the question and renders the pending page with valid params" do
      patch update_conversation_path(conversation), params: { create_question: { user_question: "How much tax should I be paying?" } }

      assert_response :redirect
      follow_redirect!
      assert_select ".govuk-notification-banner__heading", text: "GOV.UK Chat is generating an answer"
    end

    it "renders the conversation with an error when the params are invalid" do
      patch update_conversation_path(conversation), params: { create_question: { user_question: "" } }

      assert_response :unprocessable_entity
      assert_select ".govuk-error-summary a[href='#create_question_user_question']", text: "Enter a question"
      assert_select ".gem-c-label", text: "Enter a question"
    end
  end

  def renders_the_create_question_form
    assert_select ".gem-c-label", text: "Enter a question"
  end
end
