RSpec.describe "SignUpController" do
  it_behaves_like "redirects user to instant access start page when email is not in the sign_up session",
                  routes: {
                    sign_up_user_description_path: %i[get post],
                    sign_up_reason_for_visit_path: %i[get post],
                    sign_up_found_chat_path: %i[get post],
                  }

  it_behaves_like "redirects user to user description path when email is set in the session but user description isn't",
                  routes: {
                    sign_up_reason_for_visit_path: %i[get post],
                    sign_up_found_chat_path: %i[get post],
                  }

  it_behaves_like "redirects user to reason for visit path when previous sign up steps have been completed but reason for visit hasn't",
                  routes: { sign_up_found_chat_path: %i[get post] }

  it_behaves_like "renders not_accepting_signups page when Settings#sign_up_enabled is false",
                  routes: {
                    sign_up_user_description_path: %i[get post],
                    sign_up_reason_for_visit_path: %i[get post],
                  }

  it_behaves_like "redirects the user to the sign in or up page when the user is signed in",
                  routes: {
                    sign_up_user_description_path: %i[get post],
                    sign_up_reason_for_visit_path: %i[get post],
                  }

  it_behaves_like "redirects to homepage if authentication is not enabled",
                  routes: {
                    sign_up_user_description_path: %i[get post],
                    sign_up_reason_for_visit_path: %i[get post],
                  }

  it_behaves_like "throttles traffic from a single IP address",
                  routes: { sign_up_found_chat_path: %i[post] }, limit: 10, period: 5.minutes

  describe "GET :user_description" do
    include_context "with early access user email provided"

    it "renders successfully" do
      question_config = Rails.configuration.pilot_user_research_questions.user_description
      get sign_up_user_description_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".gem-c-radio__heading-text", text: question_config.fetch("text"))
    end
  end

  describe "POST :confirm_user_description" do
    include_context "with early access user email provided"

    context "when invalid params are passed" do
      it "renders the user_description page with errors" do
        post sign_up_user_description_path
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end

    context "when valid params are passed" do
      it "redirects to the reason_for_visit path" do
        post sign_up_user_description_path(
          user_description_form: { choice: "business_owner_or_self_employed" },
        )
        expect(response).to redirect_to(sign_up_reason_for_visit_path)
      end

      it "adds the user description to session['sign_up']" do
        post sign_up_user_description_path(
          user_description_form: { choice: "business_owner_or_self_employed" },
        )
        expect(session["sign_up"])
          .to eq({
            "email" => "email@test.com",
            "previous_sign_up_denied" => false,
            "user_description" => "business_owner_or_self_employed",
          })
      end
    end
  end

  describe "GET :reason_for_visit" do
    include_context "with early access user email and user description provided"

    it "renders successfully" do
      question_config = Rails.configuration.pilot_user_research_questions.reason_for_visit
      get sign_up_reason_for_visit_path
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-radio__heading-text", text: question_config.fetch("text"))
    end
  end

  describe "POST :confirm_reason_for_visit" do
    include_context "with early access user email and user description provided"

    context "when invalid params are passed" do
      it "renders the reason_for_visit page with errors" do
        post sign_up_reason_for_visit_path
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end

    context "when valid params are passed" do
      it "redirects to the found_chat path" do
        post sign_up_reason_for_visit_path(
          reason_for_visit_form: { choice: "find_specific_answer" },
        )
        expect(response).to redirect_to(sign_up_found_chat_path)
      end

      it "adds the reason for visit to session['sign_up']" do
        post sign_up_reason_for_visit_path(
          reason_for_visit_form: { choice: "find_specific_answer" },
        )
        expect(session["sign_up"])
          .to eq(
            {
              "email" => "email@test.com",
              "user_description" => "business_owner_or_self_employed",
              "reason_for_visit" => "find_specific_answer",
              "previous_sign_up_denied" => false,
            },
          )
      end
    end
  end

  describe "GET :found_chat" do
    include_context "with early access user email, user description and reason for visit provided"

    it "renders successfully" do
      question_config = Rails.configuration.pilot_user_research_questions.found_chat
      get sign_up_found_chat_path
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-radio__heading-text", text: question_config.fetch("text"))
    end
  end

  describe "POST :confirm_found_chat" do
    context "when the user description given was 'none'" do
      include_context "with early access user email, user description and reason for visit provided", "none"

      it "shows a denied page" do
        post sign_up_found_chat_path

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to have_content("You cannot currently use GOV.UK Chat")
        expect(session["sign_up"]).to be_nil
      end

      it 'sets session["sign_up_denied"] to true' do
        post sign_up_found_chat_path

        expect(session["sign_up_denied"]).to be(true)
      end
    end

    context "when invalid params are passed" do
      include_context "with early access user email, user description and reason for visit provided"

      it "renders the sign_up_found_chat page with errors" do
        post sign_up_found_chat_path
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end

    context "when valid params are passed" do
      include_context "with early access user email, user description and reason for visit provided"

      context "and user already has access" do
        it "responds with a conflict status and tells the user an account already exists" do
          create(:early_access_user, email: "email@test.com")
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(response).to have_http_status(:conflict)
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You already have access to GOV.UK Chat")
        end
      end

      context "and the user is already on the waiting list" do
        it "responds with a conflict status and tells the user an account already exists" do
          create(:waiting_list_user, email: "email@test.com")
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(response).to have_http_status(:conflict)
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You're already on the waitlist")
        end
      end

      context "and there are instant access places available" do
        it "responds with a successful status" do
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the sign_up_successful template" do
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You can now start using GOV.UK Chat")
        end

        it "deletes the session['sign_up'] variable" do
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(session["sign_up"]).to be_nil
        end
      end

      context "and there are no instant access places, but waiting list places are available" do
        before do
          Settings.instance.update!(instant_access_places: 0)
        end

        it "responds with a successful status" do
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the waitlist template" do
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You have been added to the waitlist")
        end

        it "deletes the session['sign_up'] variable" do
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(session["sign_up"]).to be_nil
        end
      end

      context "and there are no instant access places or waiting list places available" do
        before do
          Settings.instance.update!(instant_access_places: 0, max_waiting_list_places: 0)
        end

        it "responds with a successful status" do
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the waitlist full template" do
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(response.body)
            .to have_selector(".govuk-heading-xl", text: "The GOV.UK Chat waitlist is currently full")
        end

        it "deletes the session['sign_up'] variable" do
          post sign_up_found_chat_path(
            found_chat_form: { choice: "search_engine" },
          )
          expect(session["sign_up"]).to be_nil
        end
      end
    end
  end
end
