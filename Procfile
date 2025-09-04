release: bin/rails db:prepare
web: bin/rails server -p ${PORT:-5000}
answer-worker: bundle exec sidekiq -C ./config/sidekiq_answer.yml
default-worker: bundle exec sidekiq -C ./config/sidekiq_default.yml
