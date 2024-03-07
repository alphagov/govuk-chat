RSpec.describe "ConversationsController" do
  describe "GET :new" do
    it "renders the correct fields" do
      get new_conversation_path

      assert_response :success
      assert_select ".gem-c-label", text: "Enter a question"
    end
  end

  describe "POST :create" do
    it "saves the question and renders the new conversation page with valid params" do
      post create_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }

      assert_response :redirect
      follow_redirect!
      assert_select ".gem-c-success-alert__message", text: "Question saved"
      assert_select ".gem-c-label", text: "Enter a question"
    end

    it "renders the new conversation page with an error when the params are invalid" do
      post create_conversation_path, params: { create_question: { user_question: "" } }

      assert_response :unprocessable_entity
      assert_select ".govuk-error-summary a[href='#create_question_user_question']", text: "Enter a question"
      assert_select ".gem-c-label", text: "Enter a question"
    end
  end
end
