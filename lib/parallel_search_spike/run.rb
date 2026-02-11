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
      @fail_fast = !fail_fast.nil?
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
        pool_size: %i[parallel_per_phrase hybrid].include?(strategy) ? effective_pool_size : nil,
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
      return [] if phrases.empty?

      min_score = Rails.configuration.search.thresholds.minimum_score
      max_results = Rails.configuration.search.thresholds.max_results
      max_chunks = Rails.configuration.search.thresholds.retrieved_from_index

      phrase_results = Array.new(phrases.length)
      embedding_durations = {}
      embeddings = []
      phrase_indexes_by_embedding = []

      phrases.each_with_index do |phrase, phrase_index|
        embedding_start_time = Clock.monotonic_time

        begin
          embeddings << Search::TextToEmbedding.call(phrase)
          phrase_indexes_by_embedding << phrase_index
          embedding_durations[phrase_index] = Clock.monotonic_time - embedding_start_time
        rescue StandardError => e
          phrase_results[phrase_index] = phrase_error(phrase, e).merge(
            metrics: {
              embedding_provider: "titan",
              embedding_duration: Clock.monotonic_time - embedding_start_time,
            },
          )
        end
      end

      return phrase_results if embeddings.empty?

      search_start_time = Clock.monotonic_time
      msearch_results = Search::ChunkedContentRepository.new.msearch_by_embeddings(
        embeddings,
        max_chunks:,
        max_concurrent_searches: msearch_concurrency,
      )
      search_duration = Clock.monotonic_time - search_start_time

      msearch_results.each_with_index do |msearch_result, msearch_index|
        phrase_index = phrase_indexes_by_embedding[msearch_index]
        phrase = phrases[phrase_index]

        if msearch_result.error
          phrase_results[phrase_index] = {
            phrase:,
            result_count: 0,
            top_titles: [],
            metrics: {
              embedding_provider: "titan",
              embedding_duration: embedding_durations[phrase_index],
              search_duration:,
              search_strategy: "msearch_only",
            },
            error: msearch_error_to_hash(msearch_result.error),
          }
          next
        end

        reranking_start_time = Clock.monotonic_time
        accepted_results = rerank_and_filter(msearch_result.results, min_score:, max_results:)
        reranking_duration = Clock.monotonic_time - reranking_start_time

        phrase_results[phrase_index] = {
          phrase:,
          result_count: accepted_results.size,
          top_titles: accepted_results.first(top_n).map(&:title),
          metrics: {
            embedding_provider: "titan",
            embedding_duration: embedding_durations[phrase_index],
            search_duration:,
            reranking_duration:,
            search_strategy: "msearch_only",
          },
          error: nil,
        }
      end

      phrase_results
    rescue StandardError => e
      phrases.map { |phrase| phrase_error(phrase, e) }
    end

    def run_hybrid
      return [] if phrases.empty?

      min_score = Rails.configuration.search.thresholds.minimum_score
      max_results = Rails.configuration.search.thresholds.max_results
      max_chunks = Rails.configuration.search.thresholds.retrieved_from_index

      phrase_results = Array.new(phrases.length)
      embeddings_by_index = Array.new(phrases.length)
      embedding_durations = Array.new(phrases.length)

      work_items = Queue.new
      phrases.each_with_index do |phrase, phrase_index|
        work_items << [phrase, phrase_index]
      end

      thread_count = effective_pool_size
      thread_errors = Queue.new

      threads = thread_count.times.map do
        Thread.new do
          wrap_in_executor do
            loop do
              phrase, phrase_index = work_items.pop(true)
              embedding_start_time = Clock.monotonic_time

              begin
                embeddings_by_index[phrase_index] = Search::TextToEmbedding.call(phrase)
                embedding_durations[phrase_index] = Clock.monotonic_time - embedding_start_time
              rescue StandardError => e
                phrase_results[phrase_index] = phrase_error(phrase, e).merge(
                  metrics: {
                    embedding_provider: "titan",
                    embedding_duration: Clock.monotonic_time - embedding_start_time,
                  },
                )
              end
            rescue ThreadError
              break
            end
          end
        rescue StandardError => e
          thread_errors << e
        end
      end

      threads.each(&:join)
      raise thread_errors.pop unless thread_errors.empty?

      embeddings = []
      phrase_indexes_by_embedding = []
      phrases.each_index do |phrase_index|
        embedding = embeddings_by_index[phrase_index]
        next unless embedding

        embeddings << embedding
        phrase_indexes_by_embedding << phrase_index
      end

      return phrase_results if embeddings.empty?

      search_start_time = Clock.monotonic_time
      msearch_results = Search::ChunkedContentRepository.new.msearch_by_embeddings(
        embeddings,
        max_chunks:,
        max_concurrent_searches: msearch_concurrency,
      )
      search_duration = Clock.monotonic_time - search_start_time

      msearch_results.each_with_index do |msearch_result, msearch_index|
        phrase_index = phrase_indexes_by_embedding[msearch_index]
        phrase = phrases[phrase_index]

        if msearch_result.error
          phrase_results[phrase_index] = {
            phrase:,
            result_count: 0,
            top_titles: [],
            metrics: {
              embedding_provider: "titan",
              embedding_duration: embedding_durations[phrase_index],
              search_duration:,
              search_strategy: "hybrid",
            },
            error: msearch_error_to_hash(msearch_result.error),
          }
          next
        end

        reranking_start_time = Clock.monotonic_time
        accepted_results = rerank_and_filter(msearch_result.results, min_score:, max_results:)
        reranking_duration = Clock.monotonic_time - reranking_start_time

        phrase_results[phrase_index] = {
          phrase:,
          result_count: accepted_results.size,
          top_titles: accepted_results.first(top_n).map(&:title),
          metrics: {
            embedding_provider: "titan",
            embedding_duration: embedding_durations[phrase_index],
            search_duration:,
            reranking_duration:,
            search_strategy: "hybrid",
          },
          error: nil,
        }
      end

      phrase_results
    rescue StandardError => e
      phrases.map { |phrase| phrase_error(phrase, e) }
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
        io.puts "== #{run[:strategy]} (#{sprintf('%.3fs', run[:duration_s])}) =="

        run[:phrase_results].each_with_index do |phrase_result, index|
          if phrase_result[:error]
            io.puts sprintf(
              "[%02d] ERROR %s - %s",
              index,
              phrase_result.dig(:error, :class),
              phrase_result.dig(:error, :message),
            )
          else
            io.puts sprintf(
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

    def rerank_and_filter(results, min_score:, max_results:)
      weighted_results = Search::ResultsForQuestion::Reranker.call(results)
      weighted_results.select { |result| result.weighted_score >= min_score }.take(max_results)
    end

    def msearch_concurrency
      value = ENV.fetch("PARALLEL_SEARCH_MSEARCH_CONCURRENCY", nil)
      return nil unless value

      concurrency = value.to_i
      concurrency.positive? ? concurrency : nil
    end

    def msearch_error_to_hash(error)
      {
        class: "OpenSearch::MsearchItemError",
        message: error["reason"] || error.to_json,
      }
    end

    def format_error(exception)
      { class: exception.class.name, message: exception.message }
    end
  end
end
