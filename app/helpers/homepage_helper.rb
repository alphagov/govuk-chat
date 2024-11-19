module HomepageHelper
  def assign_homepage_layout_classes
    content_for(:html_class, "app-landing-page-layout")
    content_for(:body_class, "app-landing-page-layout__body")
    content_for(:main_class, "app-landing-page-layout__main")
  end
end
