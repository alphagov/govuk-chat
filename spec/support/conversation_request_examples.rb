module ConversationRequestExamples
  shared_examples "handles a request for a user who hasn't completed onboarding" do |routes:|
    include_context "when signed in"
    let(:route_params) { [] }

    routes.each do |path, methods|
      describe "requires onboarding to have been completed for #{path} route" do
        methods.each do |method|
          context "when it is a HTML request" do
            it "redirects users who aren't onboarded for #{method} #{path}" do
              process(method.to_sym, public_send(path.to_sym, *route_params), params: { format: :html })

              expect(response).to have_http_status(:redirect)
              expect(response).to redirect_to(onboarding_limitations_path)
            end
          end

          context "when it is a JSON request" do
            it "responds with a bad request for users who aren't onboarded for #{method} #{path}" do
              process(method.to_sym, public_send(path.to_sym, *route_params), params: { format: :json })

              expect(response).to have_http_status(:bad_request)
            end
          end
        end
      end
    end
  end

  shared_examples "requires a users conversation cookie to reference an active conversation" do |routes:|
    let(:route_params) { [] }
    include_context "when signed in"
    include_context "with onboarding completed"

    shared_examples "redirects a HTML request" do |path, method|
      it "deletes the cookie and redirects to onboarding_limitations for #{method} #{path}" do
        process(method.to_sym, public_send(path.to_sym, *route_params), params: { format: :html })

        expect(cookies[:conversation_id]).to be_blank
        expect(response).to redirect_to(onboarding_limitations_path)
      end
    end

    shared_examples "denies a JSON request" do |path, method|
      it "deletes the cookie and returns a 404 for #{method} #{path}" do
        process(method.to_sym, public_send(path.to_sym, *route_params), params: { format: :json })

        expect(cookies[:conversation_id]).to be_blank
        expect(response).to have_http_status(:not_found)
      end
    end

    routes.each do |path, methods|
      describe "requires a users conversation cookie to reference an active conversation for #{path}" do
        methods.each do |method|
          context "when conversation cookie doesn't reference a conversation" do
            before { cookies[:conversation_id] = "unknown" }

            include_examples "redirects a HTML request", path, method
            include_examples "denies a JSON request", path, method
          end

          context "when conversation cookie references a conversation associated with a different user" do
            before do
              conversation = create(:conversation)
              cookies[:conversation_id] = conversation.id
            end

            include_examples "redirects a HTML request", path, method
            include_examples "denies a JSON request", path, method
          end

          context "when the conversation has expired" do
            before do
              conversation = create(:conversation, :expired, user:)
              cookies[:conversation_id] = conversation.id
            end

            include_examples "redirects a HTML request", path, method
            include_examples "denies a JSON request", path, method
          end
        end
      end
    end
  end

  shared_examples "requires a conversation" do |routes:|
    let(:route_params) { [] }
    include_context "when signed in"
    include_context "with onboarding completed"

    routes.each do |path, methods|
      describe "requests without a conversation for #{path}" do
        methods.each do |method|
          it "redirects to onboarding limitations for a HTML request for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params), params: { format: :html })
            expect(response).to redirect_to(onboarding_limitations_path)
          end

          it "returns a to onboarding limitations for a JSON request for #{method} #{path}" do
            process(method.to_sym, public_send(path.to_sym, *route_params), params: { format: :json })
            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end
  end
end
