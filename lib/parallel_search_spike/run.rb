# frozen_string_literal: true

require "concurrent"

module ParallelSearchSpike
  class Run
    DEFAULT_POOL_SIZE = Integer(ENV.fetch("PARALLEL_SEARCH_POOL_SIZE", 2))
    DEFAULT_RUNS = Integer(ENV.fetch("PARALLEL_SEARCH_RUNS", 30))
    DEFAULT_STRATEGIES = %i[sequential parallel_per_phrase bounded_pool msearch_only hybrid].freeze
    STOCK_PHRASES = [
      "pay vat",
      "need a visa",
      "how do i pay vat",
    ].freeze

    def self.call(...) = new(...).call

    def initialize(
      phrases: STOCK_PHRASES,
      pool_size: DEFAULT_POOL_SIZE,
      strategies: DEFAULT_STRATEGIES,
      runs: DEFAULT_RUNS,
      io: $stdout
    )
      @phrases = Array(phrases)
      @pool_size = [pool_size.to_i, 1].max
      @strategies = Array(strategies).map(&:to_sym)
      @runs = [runs.to_i, 1].max
      @io = io
    end

    def call
      durations_by_strategy = strategies.index_with { |_strategy| [] }
      failures_by_strategy = strategies.index_with { |_strategy| 0 }

      runs.times do
        strategies.shuffle.each do |strategy|
          result = run_strategy(strategy)
          durations_by_strategy.fetch(strategy) << result[:duration_s]
          failures_by_strategy[strategy] += result[:failures]
        end
      end

      summary = summarize(durations_by_strategy, failures_by_strategy)
      print_report(summary)
      summary
    end

  private

    attr_reader :phrases, :pool_size, :strategies, :runs, :io

    def run_strategy(strategy)
      start_time = Clock.monotonic_time

      failures =
        case strategy
        when :sequential
          run_sequential
        when :parallel_per_phrase
          run_parallel_per_phrase
        when :bounded_pool
          run_bounded_pool
        when :msearch_only
          run_msearch_only
        when :hybrid
          run_hybrid
        else
          raise ArgumentError, "Unknown strategy: #{strategy.inspect}"
        end

      { duration_s: Clock.monotonic_time - start_time, failures: }
    rescue StandardError
      { duration_s: Clock.monotonic_time - start_time, failures: phrases.length }
    end

    def run_sequential
      phrases.count { |phrase| !run_one_phrase_pipeline(phrase) }
    end

    def run_parallel_per_phrase
      run_parallel_failures(
        thread_count: effective_pool_size,
        phrase_runner: method(:run_one_phrase_pipeline),
      )
    end

    def run_bounded_pool
      run_bounded_pool_failures(
        thread_count: effective_pool_size,
        phrase_runner: method(:run_one_phrase_pipeline),
      )
    end

    def run_parallel_failures(thread_count:, phrase_runner:)
      return 0 if phrases.empty?

      failures = Concurrent::AtomicFixnum.new(0)
      work = Queue.new
      phrases.each { |phrase| work << phrase }

      worker = build_worker(work:, failures:, phrase_runner:)
      threads = thread_count.times.map { Thread.new { worker.call } }
      threads.each(&:join)

      failures.value
    end

    def run_bounded_pool_failures(thread_count:, phrase_runner:)
      return 0 if phrases.empty?

      failures = Concurrent::AtomicFixnum.new(0)
      work = Queue.new
      phrases.each { |phrase| work << phrase }

      worker = build_worker(work:, failures:, phrase_runner:)
      pool = Concurrent::FixedThreadPool.new(
        thread_count,
        name: "parallel-search-spike",
      )

      begin
        thread_count.times { pool.post { worker.call } }
      ensure
        pool.shutdown
        pool.wait_for_termination
      end

      failures.value
    end

    def run_msearch_only
      embeddings = []
      failures = 0

      phrases.each do |phrase|
        embeddings << Search::TextToEmbedding.call(phrase)
      rescue StandardError
        failures += 1
      end

      return failures if embeddings.empty?

      thresholds = Rails.configuration.search.thresholds
      min_score = thresholds.minimum_score
      max_results = thresholds.max_results
      max_chunks = thresholds.retrieved_from_index

      msearch_results = Search::ChunkedContentRepository.new.msearch_by_embeddings(
        embeddings,
        max_chunks:,
      )

      msearch_results.each do |msearch_result|
        if msearch_result.error
          failures += 1
          next
        end

        rerank_and_filter(msearch_result.results, min_score:, max_results:)
      rescue StandardError
        failures += 1
      end

      failures
    end

    def run_hybrid
      return 0 if phrases.empty?

      embeddings = []
      embeddings_mutex = Mutex.new
      embedding_runner = lambda do |phrase|
        embedding = Search::TextToEmbedding.call(phrase)
        embeddings_mutex.synchronize { embeddings << embedding }
        true
      end

      failures = run_parallel_failures(thread_count: effective_pool_size, phrase_runner: embedding_runner)

      return failures if embeddings.empty?

      thresholds = Rails.configuration.search.thresholds
      min_score = thresholds.minimum_score
      max_results = thresholds.max_results
      max_chunks = thresholds.retrieved_from_index

      msearch_results = Search::ChunkedContentRepository.new.msearch_by_embeddings(
        embeddings,
        max_chunks:,
      )

      msearch_results.each do |msearch_result|
        if msearch_result.error
          failures += 1
          next
        end

        rerank_and_filter(msearch_result.results, min_score:, max_results:)
      rescue StandardError
        failures += 1
      end

      failures
    end

    def run_one_phrase_pipeline(phrase)
      result_set = Search::ResultsForQuestion.call(phrase)
      result_set.results
      true
    rescue StandardError
      false
    end

    def effective_pool_size
      [pool_size, phrases.length].min
    end

    def wrap_in_executor(&block)
      Rails.application.executor.wrap(&block)
    end

    def rerank_and_filter(results, min_score:, max_results:)
      weighted_results = Search::ResultsForQuestion::Reranker.call(results)
      weighted_results.select { |result| result.weighted_score >= min_score }.take(max_results)
    end

    def build_worker(work:, failures:, phrase_runner:)
      lambda do
        wrap_in_executor do
          loop do
            phrase = work.pop(true)
            failures.increment unless phrase_runner.call(phrase)
          rescue ThreadError
            break
          rescue StandardError
            failures.increment
          end
        end
      rescue StandardError
        failures.increment
      end
    end

    def summarize(durations_by_strategy, failures_by_strategy)
      sequential_p50 = median(durations_by_strategy.fetch(:sequential, []))

      strategies.map do |strategy|
        durations = durations_by_strategy.fetch(strategy)
        p50_duration = median(durations)

        {
          strategy:,
          p50_s: p50_duration,
          min_s: durations.min || 0.0,
          max_s: durations.max || 0.0,
          failures: failures_by_strategy.fetch(strategy),
          speedup_vs_sequential: speedup(sequential_p50, p50_duration),
        }
      end
    end

    def median(values)
      return 0.0 if values.empty?

      sorted_values = values.sort
      middle_index = sorted_values.length / 2

      return sorted_values.fetch(middle_index) if sorted_values.length.odd?

      (sorted_values.fetch(middle_index - 1) + sorted_values.fetch(middle_index)) / 2.0
    end

    def speedup(sequential_p50, p50_duration)
      return nil if sequential_p50.zero? || p50_duration.zero?

      sequential_p50 / p50_duration
    end

    def print_report(summary)
      io.puts "Parallel search spike"
      io.puts "phrases=#{phrases.length} strategies=#{strategies.inspect} pool_size=#{effective_pool_size} runs=#{runs}"

      summary.each do |row|
        speedup_text = row[:speedup_vs_sequential] ? sprintf("x%.2f", row[:speedup_vs_sequential]) : "n/a"
        io.puts(
          "#{row[:strategy]} p50=#{sprintf('%.3f', row[:p50_s])}s " \
          "min=#{sprintf('%.3f', row[:min_s])}s " \
          "max=#{sprintf('%.3f', row[:max_s])}s " \
          "failures=#{row[:failures]} speedup=#{speedup_text}",
        )
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require_relative "../../config/environment"
  ParallelSearchSpike::Run.call
end
