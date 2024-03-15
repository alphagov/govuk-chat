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

    context "when :open_ai is enabled for an actor only" do
      before do
        Flipper.enable_actor(:open_ai, AnonymousUser.new("known-user"))
      end

      context "when anonymous user is mapped to a enabled actor" do
        before do
          get new_conversation_path(params: { user: "known-user" })
        end

        it "enqueues a GenerateAnswerFromOpenAiJob" do
          expect {
            post create_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }
          }.to change(enqueued_jobs, :size).by(1)
          expect(enqueued_jobs.last)
            .to include(
              job: GenerateAnswerFromOpenAiJob,
              args: [Question.last.id],
            )
        end
      end

      context "when anonymous user is really unknown" do
        before do
          get new_conversation_path
        end

        it "enqueues a GenerateAnswerFromChatApi" do
          expect {
            post create_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }
          }.to change(enqueued_jobs, :size).by(1)
          expect(enqueued_jobs.last)
            .to include(
              job: GenerateAnswerFromChatApiJob,
              args: [Question.last.id],
            )
        end
      end
    end
  end
end
