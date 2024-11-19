RSpec.describe HomepageHelper do
  describe "#assign_homepage_layout_classes" do
    it "assigns the correct classes to the content_for variables" do
      helper.assign_homepage_layout_classes

      expect(helper.content_for(:html_class)).to eq("app-landing-page-layout")
      expect(helper.content_for(:body_class)).to eq("app-landing-page-layout__body")
      expect(helper.content_for(:main_class)).to eq("app-landing-page-layout__main")
    end
  end
end
