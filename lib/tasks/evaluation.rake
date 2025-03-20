namespace :evaluation do
  desc "Export JSONL data for auto-evaluation"
  task :generate_report, %i[input_path output_path] => :environment do |task, args|
    input_path = args[:input_path]
    output_path = args[:output_path]

    if input_path.blank?
      msg = <<-MSG
        Usage: #{task.name}[evaluation_questions_file_path, output_file_path]

        `evaluation_questions_file_path` should point to a YAML file of evaluation questions formatted as an array, e.g.

        - How do I pay VAT?
        - Do I need a visa?

        `output_file_path` is optional and, if set, will be used to write the results to a JSONL file.
      MSG

      raise msg
    end

    ENV["GOVUK_WEBSITE_ROOT"] ||= "https://www.gov.uk"

    results = Evaluation::ReportGenerator.call(input_path) do |total, current, evaluation_question|
      puts "(#{current} / #{total}): #{evaluation_question}"
    end

    jsonl = results.map(&:to_json).join("\n")

    if output_path.present?
      File.open(output_path, "wb") { |file| file.write(jsonl) }
      puts "Written to #{output_path}"
    else
      puts jsonl
    end
  end

  desc "Generate a single answer to a question returned as JSON, for 3rd party evaluation tools"
  task generate_answer: :environment do
    raise "requires a QUESTION env var" if ENV["QUESTION"].blank?

    question = Question.new(message: ENV["QUESTION"], conversation: Conversation.new)
    answer = AnswerComposition::Composer.call(question)
    puts({ message: answer.message }.to_json)
  end

  desc "Produce the output of the jailbreak response for a user input"
  task :generate_jailbreak_guardrail_response, %i[provider] => :environment do |_, args|
    raise "Requires an INPUT env var" if ENV["INPUT"].blank?
    raise "Requires a provider" if args[:provider].blank?

    # TODO: Update once we support providers other than OpenAI
    raise "Unsupported provider: #{args[:provider]}" unless args[:provider] == "openai"

    response = Guardrails::JailbreakChecker.call(ENV["INPUT"])

    puts(response.to_json)
  end
end
