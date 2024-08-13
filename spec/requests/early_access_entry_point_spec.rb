RSpec.describe "early access entry point" do
  describe "GET :new" do
    it "renders successfully" do
      get early_access_entry_path
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".govuk-heading-xl", text: "Try GOV.UK Chat")
        .and have_selector("form[action='#{early_access_entry_path}']")
    end
  end

  describe "POST :create" do
    let(:early_access_user) { create :early_access_user }

    context "when valid params are passed" do
      context "and the user doesn't have an account" do
        it "sets the users email_address in the session" do
          post early_access_entry_path(
            early_access_entry_form: { email: "email@test.com" },
          )
          expect(session["sign_up"]).to eq({ "email" => "email@test.com" })
        end

        it "redirects to the user_description path" do
          post early_access_entry_path(
            early_access_entry_form: { email: "email@test.com" },
          )
          expect(response).to redirect_to(early_access_entry_user_description_path)
        end
      end

      context "and the user already has an account" do
        it "responds with a successful status" do
          post early_access_entry_path(
            early_access_entry_form: { email: early_access_user.email },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the email_sent template" do
          post early_access_entry_path(
            early_access_entry_form: { email: early_access_user.email },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You've been sent a new link")
        end

        it "creates a passwordless session" do
          expect {
            post early_access_entry_path(
              early_access_entry_form: { email: early_access_user.email },
            )
          }.to change(Passwordless::Session, :count).by(1)
        end

        it "emails a magic link to the user" do
          expect {
            post early_access_entry_path(
              early_access_entry_form: { email: early_access_user.email },
            )
          }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        end
      end

      context "and the user has a revoked account" do
        before do
          early_access_user.touch(:revoked_at)
        end

        it "responds with a forbidden status" do
          post early_access_entry_path(
            early_access_entry_form: { email: early_access_user.email },
          )
          expect(response).to have_http_status(:forbidden)
        end

        it "renders the access revoked template" do
          post early_access_entry_path(
            early_access_entry_form: { email: early_access_user.email },
          )
          expect(response.body)
            .to have_selector(".govuk-heading-xl", text: "You do not have access to this page")
            .and have_link("report a technical fault", href: "#{Plek.website_root}/contact/govuk")
        end

        it "doesn't send a magic link to the user" do
          expect {
            post early_access_entry_path(
              early_access_entry_form: { email: early_access_user.email },
            )
          }.not_to change(EarlyAccessAuthMailer.deliveries, :count)
        end
      end
    end

    context "when invalid params are passed" do
      it "renders the new page with errors" do
        post early_access_entry_path(early_access_entry_form: { email: "" })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end
  end

  describe "GET :user_description" do
    context "when a user email is not in the sign_up session" do
      it "redirects to the reason_for_visit path" do
        get early_access_entry_user_description_path(
          user_description_form: { choice: "business_owner_or_self_employed" },
        )
        expect(response).to redirect_to(early_access_entry_path)
      end
    end

    context "when a user email is in the sign_up session" do
      before do
        post early_access_entry_path(
          early_access_entry_form: { email: "email@test.com" },
        )
      end

      it "renders successfully" do
        get early_access_entry_user_description_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to have_selector(".gem-c-radio__heading-text", text: "Which of the following best describes you?")
      end
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
        expect(response).to redirect_to(early_access_entry_path)
      end
    end

    context "when a user email is in session['sign_up']" do
      before do
        post early_access_entry_path(
          early_access_entry_form: { email: "email@test.com" },
        )
      end

      context "and invalid params are passed" do
        it "renders the user_description page with errors" do
          post early_access_entry_user_description_path(user_description_form: { choice: "" })
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to have_selector(".govuk-error-summary")
        end
      end

      context "and valid params are passed" do
        it "adds the user description to session['sign_up']" do
          post early_access_entry_user_description_path(
            user_description_form: { choice: "business_owner_or_self_employed" },
          )
          expect(session["sign_up"])
            .to eq({ "email" => "email@test.com", "user_description" => "business_owner_or_self_employed" })
        end
      end
    end
  end
end
