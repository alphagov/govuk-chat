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

    answer_strategy = Rails.configuration.answer_strategy

    puts "Generating report with answer strategy: #{answer_strategy}"

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
  task :generate_answer, %i[answer_strategy] => :environment do |_, args|
    raise "requires a QUESTION env var" if ENV["QUESTION"].blank?

    answer_strategy = args.fetch(:answer_strategy, Rails.configuration.answer_strategy)
    warn "No answer strategy argument provided, using #{answer_strategy}" unless args[:answer_strategy]

    question = Question.new(message: ENV["QUESTION"], conversation: Conversation.new, answer_strategy:)
    answer = AnswerComposition::Composer.call(question)

    if answer.status =~ /^error/
      warn "Warning: answer has an error status: #{answer.status}"
      warn answer.error_message
    end

    puts({ message: answer.message }.to_json)
  end

  desc "Produce the output of the jailbreak response for a user input"
  task :generate_jailbreak_guardrail_response, %i[provider] => :environment do |_, args|
    raise "Requires an INPUT env var" if ENV["INPUT"].blank?
    raise "Requires a provider" if args[:provider].blank?

    begin
      response = Guardrails::JailbreakChecker.call(ENV["INPUT"], args[:provider].to_sym)

      puts({ success: response }.to_json)
    rescue Guardrails::JailbreakChecker::ResponseError => e
      puts({ response_error: e }.to_json)
    end
  end

  desc "Produce the output guardrails response for a user input"
  task :generate_output_guardrail_response, %i[provider guardrail_type] => :environment do |_, args|
    raise "Requires an INPUT env var" if ENV["INPUT"].blank?
    raise "Requires a provider" if args[:provider].blank?
    raise "Requires a guardrail type" if args[:guardrail_type].blank?

    response = Guardrails::MultipleChecker.call(ENV["INPUT"], args[:guardrail_type].to_sym, args[:provider].to_sym)

    puts(response.to_json)
  end

  desc "Produce the output of a RAG response for a user input"
  task :generate_rag_structured_answer_response, %i[llm_provider] => :environment do |_, args|
    raise "Requires an INPUT env var" if ENV["INPUT"].blank?
    raise "Requires an llm provider" if args[:llm_provider].blank?

    question = Question.new(message: ENV["INPUT"], conversation: Conversation.new)

    answer = case args[:llm_provider]
             when "openai"
               AnswerComposition::PipelineRunner.call(question:, pipeline: [
                 AnswerComposition::Pipeline::SearchResultFetcher,
                 AnswerComposition::Pipeline::OpenAI::StructuredAnswerComposer,
               ])
             when "claude"
               AnswerComposition::PipelineRunner.call(question:, pipeline: [
                 AnswerComposition::Pipeline::SearchResultFetcher,
                 AnswerComposition::Pipeline::Claude::StructuredAnswerComposer,
               ])
             else
               raise "Unexpected llm provider #{args[:llm_provider]}"
             end

    raise "Error occurred generating answer: #{answer.error_message}" if answer.status =~ /^error/

    puts(answer.serialize_for_evaluation.to_json)
  end

  desc "Produce the output of question routing for a user input"
  task :generate_question_routing_response, %i[provider] => :environment do |_, args|
    raise "Requires an INPUT env var" if ENV["INPUT"].blank?
    raise "Requires a provider" if args[:provider].blank?

    klass = case args[:provider]
            when "openai"
              AnswerComposition::Pipeline::OpenAI::QuestionRouter
            when "claude"
              AnswerComposition::Pipeline::Claude::QuestionRouter
            else
              raise "Unexpected provider #{args[:provider]}"
            end

    question = Question.new(message: ENV["INPUT"], conversation: Conversation.new)
    answer = AnswerComposition::PipelineRunner.call(question:, pipeline: [klass])

    raise "Error occurred generating answer: #{answer.error_message}" if answer.status =~ /^error/

    result = {
      classification: answer.question_routing_label,
      confidence_score: answer.question_routing_confidence_score,
      answer: answer.message,
    }

    puts(result.to_json)
  end

  desc "Query the index for results matching a user input"
  task search_results_for_question: :environment do
    raise "Requires an INPUT env var" if ENV["INPUT"].blank?

    search_results = Search::ResultsForQuestion.call(ENV["INPUT"]).results

    items = search_results.map do |result|
      {
        exact_path: result.exact_path,
        plain_content: result.plain_content,
        weighted_score: result.weighted_score,
        original_score: result.score,
      }
    end

    puts(items.to_json)
  end

  desc "Produce topics for a user question"
  task generate_topics_for_question: :environment do
    raise "Requires an INPUT env var" if ENV["INPUT"].blank?

    result = AnswerAnalysisGeneration::TopicTagger.call(ENV["INPUT"])

    puts(result.to_json)
  end
end
