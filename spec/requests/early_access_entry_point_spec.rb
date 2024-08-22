RSpec.describe "early access entry point" do
  before { create(:settings) }

  it_behaves_like "redirects user to instant access start page when email is not in the sign_up session",
                  routes: {
                    early_access_entry_user_description_path: %i[get post],
                    early_access_entry_reason_for_visit_path: %i[get post],
                  }

  it_behaves_like "redirects user to user description path when email is set in the session but user description isn't",
                  routes: { early_access_entry_reason_for_visit_path: %i[get post] }

  it_behaves_like "renders not_accepting_signups page when Settings#sign_up_enabled is false",
                  routes: {
                    early_access_entry_user_description_path: %i[get post],
                    early_access_entry_reason_for_visit_path: %i[get post],
                  }
  it_behaves_like "redirects the user to the sign in or up page when the user is signed in",
                  routes: {
                    early_access_entry_user_description_path: %i[get post],
                    early_access_entry_reason_for_visit_path: %i[get post],
                  }
  it_behaves_like "redirects to chat path if auth is not required",
                  routes: {
                    early_access_entry_user_description_path: %i[get post],
                    early_access_entry_reason_for_visit_path: %i[get post],
                  }

  describe "GET :user_description" do
    include_context "with early access user email provided"

    it "renders successfully" do
      get early_access_entry_user_description_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".gem-c-radio__heading-text", text: PilotUser::USER_RESEARCH_QUESTION_DESCRIPTION)
    end
  end

  describe "POST :confirm_user_description" do
    include_context "with early access user email provided"

    context "when invalid params are passed" do
      it "renders the user_description page with errors" do
        post early_access_entry_user_description_path(user_description_form: { choice: "" })
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end

    context "when valid params are passed" do
      it "redirects to the reason_for_visit path" do
        post early_access_entry_user_description_path(
          user_description_form: { choice: "business_owner_or_self_employed" },
        )
        expect(response).to redirect_to(early_access_entry_reason_for_visit_path)
      end

      it "adds the user description to session['sign_up']" do
        post early_access_entry_user_description_path(
          user_description_form: { choice: "business_owner_or_self_employed" },
        )
        expect(session["sign_up"])
          .to eq({ "email" => "email@test.com", "user_description" => "business_owner_or_self_employed" })
      end
    end
  end

  describe "GET :reason_for_visit" do
    include_context "with early access user email and user description provided"

    it "renders successfully" do
      get early_access_entry_reason_for_visit_path
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-radio__heading-text", text: PilotUser::USER_RESEARCH_QUESTION_REASON_FOR_VISIT)
    end
  end

  describe "POST :confirm_reason_for_visit" do
    include_context "with early access user email and user description provided"

    context "when invalid params are passed" do
      it "renders the reason_for_visit page with errors" do
        post early_access_entry_reason_for_visit_path(reason_for_visit_form: { choice: "" })
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end

    context "when valid params are passed" do
      context "and user already has access" do
        it "responds with a conflict status and tells the user an account already exists" do
          create(:early_access_user, email: "email@test.com")
          post early_access_entry_reason_for_visit_path(
            reason_for_visit_form: { choice: "find_specific_answer" },
          )
          expect(response).to have_http_status(:conflict)
          expect(response.body).to have_selector(".govuk-heading-xl", text: "Account already exists")
        end
      end

      context "and the user is already on the waiting list" do
        it "responds with a conflict status and tells the user an account already exists" do
          create(:waiting_list_user, email: "email@test.com")
          post early_access_entry_reason_for_visit_path(
            reason_for_visit_form: { choice: "find_specific_answer" },
          )
          expect(response).to have_http_status(:conflict)
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You're already on the waitlist")
        end
      end

      context "and there are instant access places available" do
        it "responds with a successful status" do
          post early_access_entry_reason_for_visit_path(
            reason_for_visit_form: { choice: "find_specific_answer" },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the sign_up_successful template" do
          post early_access_entry_reason_for_visit_path(
            reason_for_visit_form: { choice: "find_specific_answer" },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You can now start using GOV.UK Chat")
        end

        it "emails a magic link to the user" do
          expect {
            post early_access_entry_reason_for_visit_path(
              reason_for_visit_form: { choice: "find_specific_answer" },
            )
          }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
          expect(EarlyAccessAuthMailer.deliveries.last.subject).to eq("Sign in")
        end

        it "deletes the session['sign_up'] variable" do
          post early_access_entry_reason_for_visit_path(
            reason_for_visit_form: { choice: "find_specific_answer" },
          )
          expect(session["sign_up"]).to be_nil
        end
      end

      context "and there are no instant access places available" do
        before do
          Settings.instance.update!(instant_access_places: 0)
        end

        it "responds with a successful status" do
          post early_access_entry_reason_for_visit_path(
            reason_for_visit_form: { choice: "find_specific_answer" },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the waitlist template" do
          post early_access_entry_reason_for_visit_path(
            reason_for_visit_form: { choice: "find_specific_answer" },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You have been added to the waitlist")
        end

        it "emails the user informing them they've been added to the waitlist" do
          expect {
            post early_access_entry_reason_for_visit_path(
              reason_for_visit_form: { choice: "find_specific_answer" },
            )
          }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
          expect(EarlyAccessAuthMailer.deliveries.last.subject).to eq("Thanks for joining the waitlist")
        end

        it "deletes the session['sign_up'] variable" do
          post early_access_entry_reason_for_visit_path(
            reason_for_visit_form: { choice: "find_specific_answer" },
          )
          expect(session["sign_up"]).to be_nil
        end
      end
    end
  end
end
