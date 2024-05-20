desc "Run all linters"
task lint: :environment do
  sh "bundle exec rubocop"
  sh "bundle exec erblint --lint-all"
  sh "yarn run lint" # lint JS and SCSS
end
