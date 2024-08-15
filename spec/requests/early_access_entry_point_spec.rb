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

  describe "GET :sign_in_or_up" do
    it "renders successfully" do
      get early_access_entry_sign_in_or_up_path
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Try GOV.UK Chat")
        .and have_selector("form[action='#{early_access_entry_sign_in_or_up_path}']")
    end
  end

  describe "POST :confirm_sign_in_or_up" do
    let(:early_access_user) { create :early_access_user }

    context "when valid params are passed" do
      context "and the user doesn't have an account" do
        it "sets the users email_address in the session" do
          post early_access_entry_sign_in_or_up_path(
            sign_in_or_up_form: { email: "email@test.com" },
          )
          expect(session["sign_up"]).to eq({ "email" => "email@test.com" })
        end

        it "redirects to the user_description path" do
          post early_access_entry_sign_in_or_up_path(
            sign_in_or_up_form: { email: "email@test.com" },
          )
          expect(response).to redirect_to(early_access_entry_user_description_path)
        end
      end

      context "and the user already has an account" do
        it "responds with a successful status" do
          post early_access_entry_sign_in_or_up_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the email_sent template" do
          post early_access_entry_sign_in_or_up_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You've been sent a new link")
        end

        it "emails a magic link to the user" do
          expect {
            post early_access_entry_sign_in_or_up_path(
              sign_in_or_up_form: { email: early_access_user.email },
            )
          }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        end
      end

      context "and the user has a revoked account" do
        before do
          early_access_user.touch(:revoked_at)
        end

        it "responds with a forbidden status" do
          post early_access_entry_sign_in_or_up_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response).to have_http_status(:forbidden)
        end

        it "renders the access revoked template" do
          post early_access_entry_sign_in_or_up_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response.body)
            .to have_selector(".govuk-heading-xl", text: "You do not have access to this page")
            .and have_link("report a technical fault", href: "#{Plek.website_root}/contact/govuk")
        end

        it "doesn't send a magic link to the user" do
          expect {
            post early_access_entry_sign_in_or_up_path(
              sign_in_or_up_form: { email: early_access_user.email },
            )
          }.not_to change(EarlyAccessAuthMailer.deliveries, :count)
        end
      end
    end

    context "when invalid params are passed" do
      it "renders the sign_in_or_up page with errors" do
        post early_access_entry_sign_in_or_up_path(sign_in_or_up_form: { email: "" })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end
  end

  describe "GET :user_description" do
    include_context "with early access user email provided"

    it "renders successfully" do
      get early_access_entry_user_description_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector(".gem-c-radio__heading-text", text: "Which of the following best describes you?")
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

      context "when a user is already signed in" do
        let(:session) { create :passwordless_session }

        before { sign_in_early_access_user(session.authenticatable) }

        it "signs the user out" do
          post early_access_entry_sign_in_or_up_path(
            sign_in_or_up_form: { email: "email@test.com" },
          )
          get protected_path
          expect(response).to redirect_to(early_access_entry_sign_in_or_up_path)
        end
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
        .to have_selector(".gem-c-radio__heading-text", text: "Why did you visit GOV.UK today?")
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
