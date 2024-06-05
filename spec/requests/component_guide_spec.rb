RSpec.describe "component guide" do
  Dir.glob(Rails.root.join("app/views/components/docs/*.yml")).each do |path|
    component = File.basename(path, ".yml")

    describe "GET /component-guide/#{component}" do
      it "returns a successful response" do
        get "/component-guide/#{component}"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
