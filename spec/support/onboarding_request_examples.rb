module OnboardingRequestExamples
  shared_examples "requires user to have completed onboarding" do |routes:|
    include_context "when signed in"
    let(:route_params) { [] }

    routes.each do |path, methods|
      describe "Requires onboarding to have been completed for #{path} route" do
        methods.each do |method|
          it "requires onboarding to have been completed for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(onboarding_limitations_path)
          end

          context "when conversation_id is set on the cookie" do
            it "does not redirect to the onboarding flow for #{method} #{path}" do
              conversation = create(:conversation, :not_expired, user:)
              cookies[:conversation_id] = conversation.id

              process(method.to_sym, public_send(path.to_sym, *route_params))

              expect(response).not_to redirect_to(onboarding_limitations_path)
            end
          end
        end
      end
    end
  end

  shared_examples "redirects user to the conversation when conversation_id is set on cookie" do |routes:|
    include_context "when signed in"

    routes.each do |path, methods|
      describe "Redirects user to the conversation when conversation_id is set on cookie" do
        methods.each do |method|
          it "redirects user to the conversation when conversation_id is present for #{method} #{path}" do
            conversation = create(:conversation, :not_expired, user:)
            cookies[:conversation_id] = conversation.id

            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(show_conversation_path)
          end
        end
      end
    end
  end

  shared_examples "redirects user to the conversation page when onboarded and no conversation cookie" do |routes:|
    include_context "when signed in"
    include_context "with onboarding completed"

    routes.each do |path, methods|
      describe "Redirects user to the new conversation page when session[:onboarding] is 'conversation'" do
        methods.each do |method|
          it "redirects user to the new conversation page when session[:onboarding] is 'conversation' for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(show_conversation_path)
          end
        end
      end
    end
  end

  shared_examples "redirects user to the conversation when an early access user has completed onboarding" do |routes:|
    include_context "when signed in"
    before { user.update!(onboarding_completed: true) }

    routes.each do |path, methods|
      describe "Redirects user to the conversation the early access users completed onboarding" do
        methods.each do |method|
          it "redirects user to the conversation when EarlyAccessUser#onboarding_completed is true for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))
            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(show_conversation_path)
          end
        end
      end
    end
  end

  shared_examples "redirects user to the privacy page when onboarding limitations has been completed" do |routes:|
    include_context "when signed in"
    include_context "with onboarding limitations completed"

    routes.each do |path, methods|
      describe "Redirects user to the privacy page when session[:onboarding] is 'privacy'" do
        methods.each do |method|
          it "redirects user to the privacy page when session[:onboarding] is 'privacy' for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(onboarding_privacy_path)
          end
        end
      end
    end
  end

  shared_examples "redirects user to the onboarding limitations page when onboarding not started" do |routes:|
    include_context "when signed in"

    routes.each do |path, methods|
      describe "Redirects user to the limitations page when session[:onboarding] isn't 'privacy' or 'conversation'" do
        methods.each do |method|
          it "redirects user to the limitations page when session[:onboarding] isn't 'privacy' or 'conversation' for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym))

            expect(response).to have_http_status(:redirect)
            expect(response).to redirect_to(onboarding_limitations_path)
          end
        end
      end
    end
  end

  shared_context "with onboarding completed" do
    before do
      post onboarding_limitations_confirm_path
      post onboarding_privacy_confirm_path
    end
  end

  shared_context "with onboarding limitations completed" do
    before do
      post onboarding_limitations_confirm_path
    end
  end
end
