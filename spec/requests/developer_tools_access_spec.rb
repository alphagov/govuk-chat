RSpec.describe "Developer Tools Access" do
  shared_examples "mounted rack app requiring developer-tools permission" do |path|
    describe "GET #{path}" do
      context "when the user has the correct permission" do
        it "returns a successful response" do
          get path
          follow_redirect! if response.redirect?
          expect(response).to have_http_status(:success)
        end
      end

      context "when the user lacks the permission" do
        before { User.first.update!(permissions: []) }

        it "returns a forbidden response" do
          get path
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  include_examples "mounted rack app requiring developer-tools permission", "/sidekiq"
  include_examples "mounted rack app requiring developer-tools permission", "/flipper"
  include_examples "mounted rack app requiring developer-tools permission", "/component-guide"
end
