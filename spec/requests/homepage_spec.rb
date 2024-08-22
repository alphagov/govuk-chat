RSpec.describe "HomepageController" do
  it_behaves_like "redirects to homepage if auth is not required",
                  routes: { homepage_path: %i[post] }

  describe "GET :index" do
    context "when early access authentication is enabled" do
      before do
        allow(Rails.configuration).to receive(:available_without_early_access_authentication).and_return(false)
      end

      it "renders the early access authentication welcome page" do
        get homepage_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to have_selector(".govuk-heading-xl", text: "Try GOV.UK Chat")
      end
    end

    context "when early access authentication is disabled" do
      before do
        allow(Rails.configuration).to receive(:available_without_early_access_authentication).and_return(true)
      end

      it "renders the welcome page" do
        get homepage_path

        expect(response).to have_http_status(:ok)
        expect(response.body)
          .to have_selector(".app-c-chat-introduction__title", text: "GOV.UK Chat")
      end
    end

    it "sets the cache headers to 5 mins" do
      get homepage_path

      expect(response.headers["Cache-Control"]).to eq("max-age=300, public")
    end

    it "skips regenerating session so the resource can be cached" do
      # create a session
      get show_conversation_path
      expect(response.cookies.keys).to include("_govuk_chat_session")

      get homepage_path
      expect(response.cookies).to be_empty
    end
  end

  describe "POST :sign_in_or_up" do
    let(:early_access_user) { create :early_access_user }

    context "when valid params are passed" do
      context "and the user doesn't have an account" do
        it "sets the users email_address in the session" do
          post homepage_path(
            sign_in_or_up_form: { email: "email@test.com" },
          )
          expect(session["sign_up"]).to eq({ "email" => "email@test.com" })
        end

        it "redirects to the user_description path" do
          post homepage_path(
            sign_in_or_up_form: { email: "email@test.com" },
          )
          expect(response).to redirect_to(early_access_entry_user_description_path)
        end
      end

      context "and the user already has an account" do
        it "responds with a successful status" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the email_sent template" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You've been sent a new link")
        end

        it "emails a magic link to the user" do
          expect {
            post homepage_path(
              sign_in_or_up_form: { email: early_access_user.email },
            )
          }.to change(EarlyAccessAuthMailer.deliveries, :count).by(1)
        end
      end

      context "and the user is on the waiting list" do
        let!(:waiting_list_user) { create :waiting_list_user }

        it "responds with a successful status" do
          post homepage_path(
            sign_in_or_up_form: { email: waiting_list_user.email },
          )
          expect(response).to have_http_status(:ok)
        end

        it "renders the already_on_waitlist template" do
          post homepage_path(
            sign_in_or_up_form: { email: waiting_list_user.email },
          )
          expect(response.body).to have_selector(".govuk-heading-xl", text: "You're already on the waitlist")
        end
      end

      context "and the user has a revoked account" do
        before do
          early_access_user.touch(:revoked_at)
        end

        it "responds with a forbidden status" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response).to have_http_status(:forbidden)
        end

        it "renders the access revoked template" do
          post homepage_path(
            sign_in_or_up_form: { email: early_access_user.email },
          )
          expect(response.body)
            .to have_selector(".govuk-heading-xl", text: "You do not have access to this page")
            .and have_link("report a technical fault", href: "https://surveys.publishing.service.gov.uk/s/govuk-chat-support")
        end

        it "doesn't send a magic link to the user" do
          expect {
            post homepage_path(
              sign_in_or_up_form: { email: early_access_user.email },
            )
          }.not_to change(EarlyAccessAuthMailer.deliveries, :count)
        end
      end
    end

    context "when invalid params are passed" do
      it "renders the sign_in_or_up page with errors" do
        post homepage_path(sign_in_or_up_form: { email: "" })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to have_selector(".govuk-error-summary")
      end
    end
  end
end
