RSpec.describe "toggling downtime with Settings.instance.api_access_enabled" do
  let(:api_user) { create(:signon_user, :conversation_api) }
  let(:conversation) { create(:conversation, :api, :with_history, signon_user: api_user) }

  before { login_as(api_user) }

  it "returns the right status when api_access_enabled is false" do
    create(:settings, api_access_enabled: false)
    get api_v0_show_conversation_path(conversation)
    expect(response).to have_http_status(:service_unavailable)
    expect(JSON.parse(response.body)["message"]).to eq("Service unavailable")
  end

  it "doesn't impact routes when api_access_enabled is true" do
    create(:settings, api_access_enabled: true)
    get api_v0_show_conversation_path(conversation)
    expect(response).to have_http_status(:ok)
  end
end
