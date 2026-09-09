namespace :answer_analysis do
  desc "Backfill request types for eligible answers that haven't been tagged"
  task backfill_request_types: :environment do
    concurrency = 10

    answers = Answer
                .where(question_routing_label: Answer::QUESTION_ROUTING_LABELS_FOR_REQUEST_TYPE_ANALYSIS)
                .where.missing(:request_types)
                .joins(:question)

    total = answers.count
    counts = { succeeded: 0, errored: 0, failed: 0 }
    mutex = Mutex.new
    processed = 0

    puts "Backfilling request types for #{total} #{'answer'.pluralize(total)} " \
         "with a concurrency of #{concurrency}"

    tag_answer = lambda do |answer_id, question_used|
      outcome = nil
      failure = nil

      begin
        result = AutoEvaluation::RequestTypeTagger.call(question_used)

        request_types = AnswerAnalysis::RequestTypes.new(
          answer_id:,
          status: result.status,
          primary_request_type: result.primary_request_type,
          secondary_request_type: result.secondary_request_type,
          confidence: result.confidence,
          reasoning: result.reasoning,
          error_message: result.error_message,
        )
        request_types.assign_metrics("request_type_tagger", result.metrics)
        request_types.assign_llm_response("request_type_tagger", result.llm_response)
        request_types.save!

        outcome = request_types.error? ? :errored : :succeeded
      rescue StandardError => e
        outcome = :failed
        failure = e
      end

      mutex.synchronize do
        counts[outcome] += 1
        processed += 1

        warn "Failed to tag answer #{answer_id}: #{failure.class}, #{failure.message}" if failure
        puts "(#{processed} / #{total})" if (processed % 100).zero? || processed == total
      end
    end

    answers.in_batches(of: 1_000) do |batch|
      queue = Thread::Queue.new
      batch.pluck(:id, :rephrased_question, "questions.message").each { queue.push(it) }
      queue.close

      threads = concurrency.times.map do
        Thread.new do
          while (row = queue.pop)
            answer_id, rephrased_question, question_message = row

            Rails.application.executor.wrap do
              tag_answer.call(answer_id, rephrased_question || question_message)
            end
          end
        end
      end

      threads.each(&:join)
    end

    puts "Tagged #{counts[:succeeded]} #{'answer'.pluralize(counts[:succeeded])}, " \
         "#{counts[:errored]} tagged with an error status, #{counts[:failed]} failed"
  end
end
