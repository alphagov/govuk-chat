module SidekiqHelpers
  def execute_queued_sidekiq_jobs
    Sidekiq::Worker.drain_all
  end
end
