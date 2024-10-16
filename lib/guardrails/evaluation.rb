module Guardrails
  # Reads a CSV file - calls the provided block with the value in the input column
  # The result is compared with the output column from the csv - metrics about
  # the number of and percentage of exact matches, along with failed examples is output.
  # Usage: Guardrails::Evaluation.call(file_path) { |input| code_to_evaluate.call(input).whatever }

  class Evaluation
    class Example
      attr_reader :input, :expected, :actual, :category, :latency, :expected_bool, :actual_bool

      def initialize(input:, expected:, actual:, category:, latency:, actual_bool:, expected_bool:)
        @input = input
        @expected = expected
        @actual = actual
        @category = category
        @latency = latency
        @expected_bool = expected_bool
        @actual_bool = actual_bool
      end

      def exact_match?
        actual == expected
      end

      def failure?
        !exact_match?
      end

      def true_positive?
        expected_bool && actual_bool
      end

      def false_positive?
        !expected_bool && actual_bool
      end

      def false_negative?
        expected_bool && !actual_bool
      end
    end

    attr_reader :examples, :file_path, :true_eval

    def initialize(file_path, true_eval:, &block)
      raise ArgumentError, "You should pass a block to #{self.class.name}.call that can process each input" unless block_given?

      @guardrail_block = block
      @file_path = file_path
      @true_eval = true_eval
      @examples = []
    end

    def self.call(...) = new(...).call

    def call
      load_csv
      {
        count:,
        percent_correct:,
        exact_match_count:,
        precision:,
        recall:,
        failure_count:,
        average_latency:,
        max_latency:,
        false_positives:,
        false_negatives:,
        failures:,
        successes:,
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
          actual_bool: true_eval.call(actual),
          expected_bool: true_eval.call(expected),
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
      examples.select(&:failure?).map(&method(:format_example))
    end

    def false_positives
      examples.select(&:false_positive?).map(&method(:format_example))
    end

    def false_negatives
      examples.select(&:false_negative?).map(&method(:format_example))
    end

    def successes
      examples.select(&:exact_match?).map(&method(:format_example))
    end

    def precision
      true_positive_count = examples.count(&:true_positive?)
      false_positive_count = examples.count(&:false_positive?)
      (true_positive_count.to_f / (true_positive_count + false_positive_count)).round(2)
    end

    def recall
      true_positive_count = examples.count(&:true_positive?)
      false_negative_count = examples.count(&:false_negative?)
      (true_positive_count.to_f / (true_positive_count + false_negative_count)).round(2)
    end

    def run_guardrail(input)
      guardrail_block.call(input)
    end

    def format_example(example)
      {
        input: example.input,
        expected: example.expected,
        actual: example.actual,
      }
    end
  end
end
