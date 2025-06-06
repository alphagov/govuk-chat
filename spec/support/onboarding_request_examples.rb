module OnboardingRequestExamples
  shared_examples "handles a user accessing onboarding when onboarded" do |routes:|
    shared_examples "redirects a HTML request" do |method, path|
      it "redirects user to the conversation when conversation_id is present for #{method} #{path}" do
        process(method.to_sym, public_send(path.to_sym), params: { format: :html })

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(show_conversation_path)
      end
    end

    shared_examples "denies a JSON request" do |method, path|
      it "returns a bad request response for #{method} #{path}" do
        process(method.to_sym, public_send(path.to_sym), params: { format: :json })

        expect(response).to have_http_status(:bad_request)
      end
    end

    routes.each do |path, methods|
      context "when conversation_id is set on cookie" do
        methods.each do |method|
          before do
            conversation = create(:conversation, :not_expired)
            cookies[:conversation_id] = conversation.id
          end

          include_examples "redirects a HTML request", method, path
          include_examples "denies a JSON request", method, path
        end
      end

      context "when session[:onboarding] is 'conversation'" do
        include_context "with onboarding completed"

        methods.each do |method|
          include_examples "redirects a HTML request", method, path
          include_examples "denies a JSON request", method, path
        end
      end
    end
  end

  shared_examples "handles a user accessing onboarding limitations once completed" do |routes:|
    include_context "with onboarding limitations completed"

    routes.each do |path, methods|
      describe "prevents users from accessing #{path} when onboarding limitations are completed" do
        methods.each do |method|
          context "when it is a HTML request" do
            it "redirects user to the privacy page for #{method} #{path}" do
              process(method.to_sym, public_send(path.to_sym), params: { format: :html })

              expect(response).to have_http_status(:redirect)
              expect(response).to redirect_to(onboarding_privacy_path)
            end
          end

          context "when it is a JSON request" do
            it "returns a bad request response for #{method} #{path}" do
              process(method.to_sym, public_send(path.to_sym), params: { format: :json })

              expect(response).to have_http_status(:bad_request)
            end
          end
        end
      end
    end
  end

  shared_examples "handles a user accessing onboarding privacy when onboarding isn't started" do |routes:|
    routes.each do |path, methods|
      describe "prevents users from accessing #{path} when onboarding isn't started" do
        methods.each do |method|
          context "when it is a HTML request" do
            it "redirects user to the limitations page for #{method} #{path}" do
              process(method.to_sym, public_send(path.to_sym), params: { format: :html })

              expect(response).to have_http_status(:redirect)
              expect(response).to redirect_to(onboarding_limitations_path)
            end
          end

          context "when it is a JSON request" do
            it "returns a bad request response for #{method} #{path}" do
              process(method.to_sym, public_send(path.to_sym), params: { format: :json })

              expect(response).to have_http_status(:bad_request)
            end
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
