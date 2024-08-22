module EarlyAccessEntryPointRequestExamples
  shared_examples "redirects user to instant access start page when email is not in the sign_up session" do |routes:|
    routes.each do |path, methods|
      describe "Redirects user to chat_path when session['sign_up']['email'] is blank" do
        methods.each do |method|
          it "redirects user to the chat_path for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(chat_path)
          end
        end
      end
    end
  end

  shared_examples "redirects user to user description path when email is set in the session but user description isn't" do |routes:|
    include_context "with early access user email provided"

    routes.each do |path, methods|
      describe "Redirects user to the user description path when session['sign_up']['user_description'] is blank" do
        methods.each do |method|
          it "redirects user to the user description path for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(early_access_entry_user_description_path)
          end
        end
      end
    end
  end

  shared_examples "renders not_accepting_signups page when Settings#sign_up_enabled is false" do |routes:|
    include_context "with early access user email and user description provided"

    routes.each do |path, methods|
      describe "Instant access signups aren't being accepted" do
        methods.each do |method|
          it "renders the not_accepting_signups page for #{method} #{path}" do
            Settings.instance.update!(sign_up_enabled: false)
            process(method.to_sym, public_send(path.to_sym))
            expect(response).to have_http_status(:forbidden)
            expect(response.body)
              .to have_selector(".govuk-heading-xl", text: "GOV.UK Chat is no longer open for new users")
          end
        end
      end
    end
  end

  shared_examples "redirects the user to the sign in or up page when the user is signed in" do |routes:|
    include_context "with early access user email and user description provided"

    routes.each do |path, methods|
      describe "early access user gets signed out when completing sign up flow" do
        methods.each do |method|
          it "redirects the user to the chat_path when signed in for #{method} #{path}" do
            session = create(:passwordless_session)
            sign_in_early_access_user(session.authenticatable)
            process(method.to_sym, public_send(path.to_sym))
            expect(response).to redirect_to(chat_path)
          end
        end
      end
    end
  end

  shared_examples "redirects to sign in page if no user signed in unless auth not required" do |routes:|
    let(:route_params) { [] }

    before do
      allow(Rails.configuration)
        .to receive(:available_without_early_access_authentication)
        .and_return(false)
    end

    routes.each do |path, methods|
      describe "Requires signed in early access user for #{path} route" do
        methods.each do |method|
          it "requires a signed in early access user for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(chat_path)
          end

          context "when auth is not required" do
            before do
              allow(Rails.configuration)
                .to receive(:available_without_early_access_authentication)
                .and_return(true)
            end

            it "does not redirect to the onboarding flow for #{method} #{path}" do
              process(method.to_sym, public_send(path.to_sym, *route_params))
              expect(response).not_to redirect_to(chat_path)
            end
          end
        end
      end
    end
  end

  shared_examples "redirects to chat path if auth is not required" do |routes:|
    let(:route_params) { [] }

    before do
      allow(Rails.configuration)
        .to receive(:available_without_early_access_authentication)
        .and_return(true)
    end

    routes.each do |path, methods|
      describe "Redirects to chat path if auth is not required for #{path} route" do
        methods.each do |method|
          it "redirects to chat path if auth is not required for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(chat_path)
          end
        end
      end
    end
  end

  shared_context "with early access user email provided" do
    before do
      post sign_in_or_up_path(
        sign_in_or_up_form: { email: "email@test.com" },
      )
    end
  end

  shared_context "with early access user email and user description provided" do
    before do
      post sign_in_or_up_path(
        sign_in_or_up_form: { email: "email@test.com" },
      )
      post early_access_entry_user_description_path(
        user_description_form: { choice: "business_owner_or_self_employed" },
      )
    end
  end
end
