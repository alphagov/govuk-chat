module ConversationRequestExamples
  shared_examples "denies a conversation request" do |path, method, format = :html|
    it "returns a 404 for #{method} #{path} #{format}" do
      process(method.to_sym, public_send(path.to_sym, *route_params), params: { format: format })

      expect(response).to have_http_status(:not_found)
    end
  end

  shared_examples "requires a users conversation cookie to reference an active conversation" do |routes:, with_json: true|
    let(:route_params) { [] }

    routes.each do |path, methods|
      describe "requires a users conversation cookie to reference an active conversation for #{path}" do
        methods.each do |method|
          context "when conversation cookie doesn't reference a conversation" do
            before { cookies[:conversation_id] = "unknown" }

            include_examples "denies a conversation request", path, method, :html
            include_examples("denies a conversation request", path, method, :json) if with_json
          end

          context "when conversation cookie references a conversation associated with a different user" do
            before do
              conversation = create(:conversation)
              cookies[:conversation_id] = conversation.id
            end

            include_examples "denies a conversation request", path, method, :html
            include_examples("denies a conversation request", path, method, :json) if with_json
          end

          context "when the conversation has expired" do
            before do
              conversation = create(:conversation, :expired)
              cookies[:conversation_id] = conversation.id
            end

            include_examples "denies a conversation request", path, method, :html
            include_examples("denies a conversation request", path, method, :json) if with_json
          end
        end
      end
    end
  end

  shared_examples "requires a conversation created via the chat interface" do |routes:|
    let(:route_params) { [] }

    routes.each do |path, methods|
      describe "requests without a conversation for #{path}" do
        methods.each do |method|
          include_examples "denies a conversation request", path, method, :html
          include_examples "denies a conversation request", path, method, :json
        end
      end

      describe "requests with a conversation which wasn't created via chat interface for #{path}" do
        before do
          conversation = create(:conversation, source: :api)
          cookies[:conversation_id] = conversation.id
        end

        methods.each do |method|
          include_examples "denies a conversation request", path, method, :html
          include_examples "denies a conversation request", path, method, :json
        end
      end
    end
  end
end
