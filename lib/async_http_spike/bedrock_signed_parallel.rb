# frozen_string_literal: true

require "json"
require "typhoeus"
require "uri"

require "aws-sdk-bedrockruntime"
require "aws-sigv4"

module AsyncHttpSpike
  class BedrockSignedParallel
    DEFAULT_REGION = ENV.fetch("AWS_REGION", ENV.fetch("AWS_DEFAULT_REGION", "eu-west-1"))
    DEFAULT_MODEL_ID = ENV.fetch("ASYNC_BEDROCK_MODEL_ID", "amazon.titan-embed-text-v2:0")
    DEFAULT_CONCURRENCY = Integer(ENV.fetch("ASYNC_BEDROCK_CONCURRENCY", 4))
    DEFAULT_TIMEOUT_MS = Integer(ENV.fetch("ASYNC_BEDROCK_TIMEOUT_MS", 20_000))
    DEFAULT_RUNS = Integer(ENV.fetch("ASYNC_BEDROCK_RUNS", 3))
    SIGV4_SERVICE = "bedrock"
    STOCK_PHRASES = [
      "apply for a passport",
      "renew a driving licence",
      "register to vote",
      "check your state pension age",
      "report a pothole",
    ].freeze

    def self.call(...) = new(...).call

    def initialize(
      region: DEFAULT_REGION,
      model_id: DEFAULT_MODEL_ID,
      concurrency: DEFAULT_CONCURRENCY,
      timeout_ms: DEFAULT_TIMEOUT_MS,
      runs: DEFAULT_RUNS,
      io: $stdout
    )
      @phrases = STOCK_PHRASES
      @region = region
      @model_id = model_id
      @concurrency = [concurrency.to_i, 1].max
      @timeout_ms = [timeout_ms.to_i, 1].max
      @runs = [runs.to_i, 1].max
      @io = io
    end

    def call
      signer = build_signer
      url = request_url
      benchmark_runs = runs.times.map { run_once(url:, signer:) }

      summary = {
        mode: "bedrock_signed_parallel",
        region:,
        model_id:,
        phrase_count: phrases.length,
        concurrency: effective_concurrency,
        runs:,
        sequential: summarize_strategy(benchmark_runs, :sequential),
        async: summarize_strategy(benchmark_runs, :async),
      }
      summary[:speedup_vs_sequential] = speedup(summary[:sequential], summary[:async])
      print_report(summary)
      summary
    end

  private

    attr_reader :phrases, :region, :model_id, :concurrency, :timeout_ms, :runs, :io

    def run_once(url:, signer:)
      {
        sequential: run_sequential(url:, signer:),
        async: run_async(url:, signer:),
      }
    end

    def run_sequential(url:, signer:)
      started = monotonic_time
      failures = phrases.count { |phrase| request_failed?(phrase:, url:, signer:) }

      {
        total_s: monotonic_time - started,
        failures:,
      }
    end

    def run_async(url:, signer:)
      return { total_s: 0.0, failures: 0 } if phrases.empty?

      started = monotonic_time
      failures = 0
      hydra = Typhoeus::Hydra.new(max_concurrency: effective_concurrency)

      phrases.each do |phrase|
        body = request_body_for(phrase)
        request = Typhoeus::Request.new(
          url,
          method: :post,
          headers: signed_headers_for(signer:, url:, body:),
          body:,
          timeout: timeout_ms,
        )

        request.on_complete do |response|
          failures += 1 unless response_success?(response)
        end
        hydra.queue(request)
      rescue StandardError
        failures += 1
      end

      hydra.run

      {
        total_s: monotonic_time - started,
        failures:,
      }
    end

    def request_failed?(phrase:, url:, signer:)
      body = request_body_for(phrase)
      response = Typhoeus::Request.new(
        url,
        method: :post,
        headers: signed_headers_for(signer:, url:, body:),
        body:,
        timeout: timeout_ms,
      ).run

      !response_success?(response)
    rescue StandardError
      true
    end

    def response_success?(response)
      response.code.between?(200, 299)
    end

    def request_body_for(phrase)
      JSON.generate(inputText: phrase)
    end

    def signed_headers_for(signer:, url:, body:)
      base_headers = unsigned_headers_for(url)
      signed_headers = signer.sign_request(
        http_method: "POST",
        url:,
        headers: base_headers,
        body:,
      ).headers
      base_headers.merge(signed_headers)
    end

    def unsigned_headers_for(url)
      uri = URI.parse(url)
      {
        "host" => uri.host,
        "content-type" => "application/json",
        "accept" => "application/json",
      }
    end

    def build_signer
      credentials = resolve_credentials
      Aws::Sigv4::Signer.new(service: SIGV4_SERVICE, region:, credentials:)
    end

    def resolve_credentials
      credentials_provider = bedrock_client.config.credentials
      credentials = credentials_provider.respond_to?(:credentials) ? credentials_provider.credentials : credentials_provider

      if credentials.nil? || (credentials.respond_to?(:set?) && !credentials.set?)
        raise "no AWS credentials found; signing cannot be validated end-to-end"
      end

      credentials
    rescue Aws::Errors::MissingCredentialsError, Aws::Sigv4::Errors::MissingCredentialsError => e
      raise e.message
    end

    def request_url
      "https://bedrock-runtime.#{region}.amazonaws.com/model/#{model_id}/invoke"
    end

    def summarize_strategy(benchmark_runs, strategy)
      strategy_runs = benchmark_runs.map { |run| run.fetch(strategy) }
      totals = strategy_runs.map { |run| run[:total_s] }
      failures = strategy_runs.sum { |run| run[:failures] }

      {
        avg_total_s: average(totals),
        min_total_s: totals.min || 0.0,
        max_total_s: totals.max || 0.0,
        failures:,
      }
    end

    def speedup(sequential_summary, async_summary)
      async_avg = async_summary[:avg_total_s]
      return nil if async_avg.zero?

      sequential_summary[:avg_total_s] / async_avg
    end

    def print_report(summary)
      io.puts "Bedrock signed parallel spike"
      io.puts "phrases=#{summary[:phrase_count]} concurrency=#{summary[:concurrency]} runs=#{summary[:runs]}"
      print_strategy_report("sequential", summary[:sequential])
      print_strategy_report("async", summary[:async])
      io.puts "speedup_vs_sequential=x#{sprintf('%.2f', summary[:speedup_vs_sequential])}" if summary[:speedup_vs_sequential]
    end

    def print_strategy_report(name, strategy_summary)
      io.puts(
        "#{name} avg_total=#{sprintf('%.3f', strategy_summary[:avg_total_s])}s " \
        "min=#{sprintf('%.3f', strategy_summary[:min_total_s])}s " \
        "max=#{sprintf('%.3f', strategy_summary[:max_total_s])}s " \
        "failures=#{strategy_summary[:failures]}",
      )
    end

    def effective_concurrency
      [concurrency, phrases.length].min
    end

    def bedrock_client
      @bedrock_client ||= Aws::BedrockRuntime::Client.new(region:)
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def average(values)
      return 0.0 if values.empty?

      values.sum(0.0) / values.length
    end
  end
end

if $PROGRAM_NAME == __FILE__
  AsyncHttpSpike::BedrockSignedParallel.call
end
