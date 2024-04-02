RSpec.describe "ChatController" do
  describe "GET :index" do
    it "renders the initial onboarding page" do
      get chat_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-title__text", text: "Welcome to GOV.UK Chat")
    end

    it "sets the cache headers to 5 mins" do
      get chat_path

      expect(response.headers["Cache-Control"]).to eq("max-age=300, public")
    end
  end

  describe "GET :onboarding" do
    it "renders the onboarding page" do
      get chat_onboarding_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-title__text", text: "Before you start")
    end
  end

  describe "POST :onboarding_confirm" do
    context "when the confirm_understand_risk[confirmation] param is present" do
      it "redirects to the new conversation page" do
        post onboarding_confirm_path, params: { confirm_understand_risk: { confirmation: "understand_risk" } }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_conversation_path)
      end

      it "sets the session cookie chat_risks_understood to true" do
        post onboarding_confirm_path, params: { confirm_understand_risk: { confirmation: "understand_risk" } }

        expect(session[:chat_risks_understood]).to eq(true)
      end

      context "when the referrer is set in the session" do
        let(:conversation) { create(:conversation) }
        let(:question) { create(:question, conversation:) }

        context "and is from the same host" do
          it "redirects to the referrer" do
            get answer_question_path(conversation, question) # Sets the referrer in the session
            post onboarding_confirm_path, params: { confirm_understand_risk: { confirmation: "understand_risk" } }

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(answer_question_path(conversation, question))
          end
        end

        context "and is from a different host" do
          it "logs the error and redirects to the the chat page" do
            expect(Rails.logger)
              .to receive(:error)
              .with("Unsuccessful unsafe redirect: Unsafe redirect to \"http://www.naughty.com/chat/conversations\", pass allow_other_host: true to redirect anyway.")

            get new_conversation_path, headers: { HTTP_X_FORWARDED_HOST: "www.naughty.com" }
            post onboarding_confirm_path, params: { confirm_understand_risk: { confirmation: "understand_risk" } }

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(chat_path)
          end
        end
      end
    end

    context "when the understand_risk param is not present" do
      it "renders the onboarding page with the error message" do
        post onboarding_confirm_path

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body)
          .to have_selector(
            ".govuk-error-summary a[href='#confirm_understand_risk_confirmation']",
            text: "Check the checkbox to show you understand the guidance",
          )
          .and have_selector(".gem-c-title__text", text: "Before you start")
      end
    end
  end
end
