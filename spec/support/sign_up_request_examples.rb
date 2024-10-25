module SignUpRequestExamples
  shared_examples "redirects user to instant access start page when email is not in the sign_up session" do |routes:|
    routes.each do |path, methods|
      describe "Redirects user to homepage_path when session['sign_up']['email'] is blank" do
        methods.each do |method|
          it "redirects user to the homepage_path for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(homepage_path)
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
            expect(response).to redirect_to(sign_up_user_description_path)
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
              .to have_selector(".govuk-heading-xl", text: "Sign up is currently closed")
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
          it "redirects the user to the homepage_path when signed in for #{method} #{path}" do
            session = create(:passwordless_session)
            sign_in_early_access_user(session.authenticatable)
            process(method.to_sym, public_send(path.to_sym))
            expect(response).to redirect_to(homepage_path)
          end
        end
      end
    end
  end

  shared_examples "redirects unauthenticated requests when authentication is required" do |routes:|
    let(:route_params) { [] }

    before do
      allow(Rails.configuration)
        .to receive(:available_without_early_access_authentication)
        .and_return(false)
    end

    routes.each do |path, methods|
      describe "requires signed in early access user for #{path} route" do
        methods.each do |method|
          it "redirects generic requests for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(homepage_path)
          end
        end
      end
    end
  end

  shared_examples "denies unauthenticated JSON requests when authentication is required" do |routes:|
    let(:route_params) { [] }

    before do
      allow(Rails.configuration)
        .to receive(:available_without_early_access_authentication)
        .and_return(false)
    end

    routes.each do |path, methods|
      describe "requires signed in early access user for #{path} route" do
        methods.each do |method|
          it "denies JSON requests for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params), params: { format: :json })

            expect(response).to have_http_status(:bad_request)
          end
        end
      end
    end
  end

  shared_examples "redirects to homepage if authentication is not enabled" do |routes:|
    let(:route_params) { [] }

    before do
      allow(Rails.configuration)
        .to receive(:available_without_early_access_authentication)
        .and_return(true)
    end

    routes.each do |path, methods|
      describe "accessing an authentication route when authenication is not required for #{path} route" do
        methods.each do |method|
          it "redirects to homepage for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(homepage_path)
          end
        end
      end
    end
  end

  shared_context "with early access user email provided" do
    before do
      post homepage_path(sign_in_or_up_form: { email: "email@test.com" })
    end
  end

  shared_context "with early access user email and user description provided" do
    before do
      post homepage_path(sign_in_or_up_form: { email: "email@test.com" })
      post sign_up_user_description_path(user_description_form: { choice: "business_owner_or_self_employed" })
    end
  end

  shared_context "with early access user email, user description and reason for visit provided" do |user_description = "business_owner_or_self_employed"|
    before do
      post homepage_path(sign_in_or_up_form: { email: "email@test.com" })
      post sign_up_user_description_path(user_description_form: { choice: user_description })
      post sign_up_reason_for_visit_path(reason_for_visit_form: { choice: "find_specific_answer" })
    end
  end
end
