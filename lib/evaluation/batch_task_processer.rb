module Evaluation
  class BatchTaskProcesser
    def self.call(...) = new(...).call

    def initialize(input_path, task_name, task_args, concurrency: 25, &block)
      raise "File #{input_path} does not exist" unless File.exist?(input_path)

      @questions = YAML.load_file(input_path)
      @task_name = if task_name.start_with?("evaluation:")
                     task_name
                   else
                     "evaluation:#{task_name}"
                   end
      @task_args = task_args
      @concurrency = concurrency
      @block = block
      @mutex = Mutex.new
    end

    def call
      results = {}
      warnings = []
      question_groups = questions.group_by.with_index { |_, index| index % concurrency }

      threads = concurrency.times.filter_map do |i|
        next unless question_groups[i]

        Thread.new { run_thread(i, question_groups[i], results, warnings) }
      end

      threads.each(&:join)
      results.values
    end

  private

    attr_reader :questions, :task_name, :task_args, :concurrency, :block, :mutex

    def run_thread(thread_index, question_group, results, warnings)
      question_group.each_with_index do |question, index|
        stdout, stderr, status = run_rake_task(question)

        # use a mutex to avoid concurrent execution of the block
        mutex.synchronize do
          unless status.exitstatus.zero?
            raise "Task failed for question \"#{question}\":\n\n#{stderr}"
          end

          # establish where to put to the result into the results hash
          # matching the position of the original question
          result_index = thread_index + (index * concurrency)
          results[result_index] = parsed_task_output(question, stdout)

          next unless block

          task_warnings = stderr.split("\n")

          # remove blank/repetitive warnings
          task_warnings.reject! { it.blank? || it.match?(/not starting Prometheus metrics server/) }

          new_warnings = task_warnings.uniq - warnings
          warnings.push(*new_warnings)

          block.call(new_warnings, questions.size, results.size)
        end
      end
    end

    def run_rake_task(question)
      env = ENV.to_h.merge("INPUT" => question)
      escaped_args = task_args.map { Shellwords.escape(it) }
      task = "#{task_name}[#{escaped_args.join(', ')}]"
      Open3.capture3(env, "bundle", "exec", "rake", task)
    end

    def parsed_task_output(question, stdout)
      {
        "input" => question,
        "output" => JSON.parse(stdout),
      }
    end
  end
end
