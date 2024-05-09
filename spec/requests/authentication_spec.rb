RSpec.describe "ApplicationController" do
  describe "configurable global signon configuration" do
    context "when the available_without_signon_authentication configuration returns nil" do
      it "redirects the user to Signon" do
        ClimateControl.modify GDS_SSO_MOCK_INVALID: "true" do
          allow(Rails.configuration).to receive(:available_without_signon_authentication).and_return(nil)
          get chat_path
          expect(response).to redirect_to("/auth/gds")
        end
      end
    end

    context "when the available_without_signon_authentication configuration returns true" do
      it "doesn't attempt to authenticate with signon and returns a 200" do
        ClimateControl.modify GDS_SSO_MOCK_INVALID: "true" do
          allow(Rails.configuration).to receive(:available_without_signon_authentication).and_return(true)
          get chat_path
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
