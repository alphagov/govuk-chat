RSpec.describe "ConversationsController" do
  include ActiveJob::TestHelper

  describe "GET :new" do
    it "renders the correct fields" do
      get new_conversation_path

      assert_response :success
      renders_the_create_question_form
    end
  end

  describe "POST :create" do
    it "saves the question and renders the new conversation page with valid params" do
      post create_conversation_path, params: { create_question: { user_question: "How much tax should I be paying?" } }

      assert_response :redirect
      follow_redirect!
      assert_select ".gem-c-success-alert__message", text: "Your question has been submitted"
      renders_the_create_question_form
    end

    it "renders the new conversation page with an error when the params are invalid" do
      post create_conversation_path, params: { create_question: { user_question: "" } }

      assert_response :unprocessable_entity
      assert_select ".govuk-error-summary a[href='#create_question_user_question']", text: "Enter a question"
      renders_the_create_question_form
    end

    context "when :open_ai is enabled for an actor only" do
      before do
        Flipper.enable_actor(:open_ai, AnonymousUser.new("known-user"))
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

      context "when anonymous user is mapped to a enabled actor" do
        it "enqueues a GenerateAnswerFromOpenAiJob" do
          expect {
            post create_conversation_path, params: {
              create_question: { user_question: "How much tax should I be paying?" },
              user_id: "known-user",
            }
          }.to change(enqueued_jobs, :size).by(1)
          expect(enqueued_jobs.last)
            .to include(
              job: GenerateAnswerFromOpenAiJob,
              args: [Question.last.id],
            )
        end
      end
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
        get show_conversation_path(question.conversation)

        assert_response :success
        assert_select "#question-#{question.id}", text: /#{question.message}/
        assert_select "#answer-#{question.answer.id}", text: /#{question.answer.message}/
      end
    end

    context "when the conversation has an unanswered question" do
      it "only renders a question" do
        question = create(:question)
        get show_conversation_path(question.conversation)

        assert_response :success
        assert_select "#question-#{question.id}", text: /#{question.message}/
      end
    end
  end

  def renders_the_create_question_form
    assert_select ".gem-c-label", text: "Enter a question"
  end
end
