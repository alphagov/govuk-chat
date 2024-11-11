module Clock
  def self.monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
