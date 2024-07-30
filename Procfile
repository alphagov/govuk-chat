# release: bin/rails db:prepare # commented out due to Heroku lack of free hours
web: bin/rails server -p ${PORT:-5000}
worker: bundle exec sidekiq -C ./config/sidekiq.yml
