APP_STYLESHEETS = {
  "application.scss" => "application.css",
  "admin.scss" => "admin.css",
  "component-guide.scss" => "component-guide.css",
}.freeze

all_stylesheets = APP_STYLESHEETS.merge(GovukPublishingComponents::Config.component_guide_stylesheet)
Rails.application.config.dartsass.builds = all_stylesheets

Rails.application.config.dartsass.build_options << " --quiet-deps"
