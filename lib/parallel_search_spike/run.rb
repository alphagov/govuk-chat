# frozen_string_literal: true

module ParallelSearchSpike
  class Run
    DEFAULT_POOL_SIZE = Integer(ENV.fetch("PARALLEL_SEARCH_POOL_SIZE", 5))
    DEFAULT_TOP_N = Integer(ENV.fetch("PARALLEL_SEARCH_TOP_N", 3))
    DEFAULT_STRATEGIES = %i[sequential parallel_per_phrase].freeze

    def self.call(...) = new(...).call

    def initialize(
      phrases:,
      pool_size: DEFAULT_POOL_SIZE,
      strategies: DEFAULT_STRATEGIES,
      top_n: DEFAULT_TOP_N,
      fail_fast: false,
      io: $stdout
    )
      @phrases = Array(phrases)
      @pool_size = pool_size.to_i
      @strategies = Array(strategies).map(&:to_sym)
      @top_n = top_n.to_i
      @fail_fast = !!fail_fast
      @io = io
    end

    def call
      runs = strategies.map { |strategy| run_strategy(strategy) }
      print_report(runs)
      runs
    end

  private

    attr_reader :phrases, :pool_size, :strategies, :top_n, :fail_fast, :io

    def run_strategy(strategy)
      start_time = Clock.monotonic_time

      phrase_results =
        case strategy
        when :sequential
          run_sequential
        when :parallel_per_phrase
          run_parallel_per_phrase
        when :msearch_only
          run_msearch_only
        when :hybrid
          run_hybrid
        else
          raise ArgumentError, "Unknown strategy: #{strategy.inspect}"
        end

      {
        strategy:,
        pool_size: strategy == :parallel_per_phrase ? effective_pool_size : nil,
        duration_s: Clock.monotonic_time - start_time,
        phrase_results:,
      }
    rescue NotImplementedError => e
      {
        strategy:,
        duration_s: 0.0,
        note: e.message,
        phrase_results: phrases.map { |phrase| phrase_error(phrase, e) },
      }
    end

    def run_sequential
      phrases.map { |phrase| run_one_phrase(phrase) }
    end

    def run_parallel_per_phrase
      return [] if phrases.empty?

      thread_count = effective_pool_size
      results = Array.new(phrases.length)
      errors = Queue.new
      phrase_groups = phrases.each_with_index.group_by { |(_, index)| index % thread_count }

      threads = thread_count.times.filter_map do |thread_index|
        next unless phrase_groups[thread_index]

        Thread.new do
          wrap_in_executor do
            phrase_groups[thread_index].each do |(phrase, index)|
              results[index] = run_one_phrase(phrase)

              next unless fail_fast && results[index][:error]

              errors << results[index][:error]
              break
            end
          end
        rescue StandardError => e
          errors << format_error(e)
        end
      end

      threads.each(&:join)

      if fail_fast && !errors.empty?
        error = errors.pop
        raise "parallel_per_phrase failed fast: #{error[:class]} - #{error[:message]}"
      end

      results
    end

    def run_msearch_only
      raise NotImplementedError, <<~MESSAGE.strip
        msearch_only is not implemented in this harness yet.

        TODO:
          1) Build phrase embeddings (likely still sequential titan calls)
          2) Build OpenSearch msearch actions in phrase order
          3) Execute one client.msearch request
          4) Map responses back to phrase-indexed summaries
          5) Optionally align reranking/threshold behaviour with ResultsForQuestion
      MESSAGE
    end

    def run_hybrid
      raise NotImplementedError, <<~MESSAGE.strip
        hybrid is not implemented in this harness yet.

        TODO:
          1) Build embeddings in parallel with a bounded pool
          2) Execute one OpenSearch msearch request for all embeddings
          3) Map and summarise responses in original phrase order
          4) Optionally align reranking/threshold behaviour with ResultsForQuestion
      MESSAGE
    end

    def run_one_phrase(phrase)
      result_set = Search::ResultsForQuestion.call(phrase)

      {
        phrase:,
        result_count: result_set.results.size,
        top_titles: result_set.results.first(top_n).map(&:title),
        metrics: result_set.metrics,
        error: nil,
      }
    rescue StandardError => e
      phrase_error(phrase, e)
    end

    def phrase_error(phrase, exception)
      {
        phrase:,
        result_count: 0,
        top_titles: [],
        metrics: {},
        error: format_error(exception),
      }
    end

    def print_report(runs)
      io.puts "Parallel search spike"
      io.puts "phrases=#{phrases.length} strategies=#{strategies.inspect} pool_size=#{pool_size} top_n=#{top_n}"
      io.puts

      runs.each do |run|
        io.puts "== #{run[:strategy]} (#{format('%.3fs', run[:duration_s])}) =="

        run[:phrase_results].each_with_index do |phrase_result, index|
          if phrase_result[:error]
            io.puts format(
              "[%02d] ERROR %s - %s",
              index,
              phrase_result.dig(:error, :class),
              phrase_result.dig(:error, :message),
            )
          else
            io.puts format(
              "[%02d] %s => %d results | top: %s",
              index,
              phrase_result[:phrase].inspect,
              phrase_result[:result_count],
              phrase_result[:top_titles].map(&:inspect).join(", "),
            )
          end
        end

        io.puts
      end

      io.puts "JSON:"
      io.puts JSON.pretty_generate(runs)
    end

    def effective_pool_size
      [[pool_size, 1].max, phrases.length].min
    end

    def wrap_in_executor(&block)
      Rails.application.executor.wrap(&block)
    end

    def format_error(exception)
      { class: exception.class.name, message: exception.message }
    end
  end
end
