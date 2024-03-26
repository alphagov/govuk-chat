release: bin/rails db:prepare
web: bin/rails server -p ${PORT:-5000}
worker: bundle exec sidekiq -C ./config/sidekiq.yml
