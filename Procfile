release: bin/rails db:prepare
web: bin/rails server -p ${PORT:-5000}
worker-high: bundle exec sidekiq -C ./config/sidekiq_high.yml
worker-low: bundle exec sidekiq -C ./config/sidekiq_low.yml
