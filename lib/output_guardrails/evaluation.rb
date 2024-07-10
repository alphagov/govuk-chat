require "csv"

module OutputGuardrails
  # Reads a CSV file - calls the provided block with the value in the input column
  # The result is compared with the output column from the csv - metrics about
  # the number of and percentage of exact matches, along with failed examples is output.
  # Usage: Evaluation::ExactMatch.call(file_path) { |input| code_to_evaluate.call(input).whatever }

  class Evaluation
    class Example
      attr_reader :input, :expected, :actual, :category, :latency

      def initialize(input:, expected:, actual:, category:, latency:)
        @input = input
        @expected = expected
        @actual = actual
        @category = category
        @latency = latency
      end

      def exact_match?
        actual == expected
      end

      def failure?
        !exact_match?
      end
    end

    attr_reader :examples, :file_path

    def initialize(file_path, &block)
      raise ArgumentError, "You should pass a block to ExactMatchEvaluation.call that can process each input" unless block_given?

      @guardrail_block = block
      @file_path = file_path
      @examples = []
    end

    def self.call(...) = new(...).call

    def call
      load_csv
      {
        count:,
        percent_correct:,
        exact_match_count:,
        failure_count:,
        average_latency:,
        max_latency:,
        failures:,
      }
    end

  private

    attr_reader :guardrail_block

    def load_csv
      CSV.foreach(file_path, headers: true) do |row|
        actual = nil
        input = row["input"]
        expected = row["output"]
        latency = Benchmark.realtime do
          actual = run_guardrail(input)
        end

        entry = Example.new(
          input:,
          expected:,
          category: row["category"],
          actual:,
          latency:,
        )
        examples << entry
      end
    end

    def count
      examples.count
    end

    def exact_match_count
      examples.count(&:exact_match?)
    end

    def failure_count
      examples.count(&:failure?)
    end

    def percent_correct
      ((exact_match_count / count.to_f) * 100).round(2)
    end

    def average_latency
      total_latency = examples.sum(&:latency)
      total_latency / examples.size
    end

    def max_latency
      examples.map(&:latency).max
    end

    def failures
      examples.select(&:failure?).map do |example|
        { input: example.input, expected: example.expected, actual: example.actual }
      end
    end

    def run_guardrail(input)
      guardrail_block.call(input)
    end
  end
end
