module SidekiqHelpers
  def execute_queued_sidekiq_jobs
    Sidekiq::Job.drain_all
  end
end
