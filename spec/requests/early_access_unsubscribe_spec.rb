RSpec.describe "EarlyAccessUnsubscribeController" do
  describe "HEAD :unsubscribe" do
    it "returns :ok with empty body" do
      head early_access_user_unsubscribe_path(id: "any", token: "any")

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty
    end
  end

  describe "GET :unsubscribe" do
    let(:user) { create(:early_access_user) }
    let(:id) { user.id }
    let(:token) { user.unsubscribe_access_token }

    before do
      create :conversation, user:
    end

    it "deletes the early access user" do
      expect { get early_access_user_unsubscribe_path(id:, token:) }.to change(EarlyAccessUser, :count).by(-1)
    end

    it "leaves the conversations in place" do
      expect { get early_access_user_unsubscribe_path(id:, token:) }.not_to change(Conversation, :count)
    end

    it "renders a conformation page" do
      get early_access_user_unsubscribe_path(id:, token:)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your access has been removed and your email address will no longer be stored")
    end

    it "returns a 404 and does nothing for invalid token" do
      expect { get early_access_user_unsubscribe_path(id:, token: "invalid-token") }
        .not_to change(EarlyAccessUser, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "returns a 404 and does nothing for invalid user" do
      expect { get early_access_user_unsubscribe_path(id: "invalid-user", token:) }
        .not_to change(EarlyAccessUser, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
