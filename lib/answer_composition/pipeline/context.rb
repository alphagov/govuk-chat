module AnswerComposition::Pipeline
  class Context
    attr_reader :question, :answer, :question_message, :search_results

    def initialize(question)
      @question = question
      @answer = question.build_answer
      @question_message = question.message
      @aborted = false
    end

    def abort_pipeline(**answer_attrs)
      @aborted = true

      if (metrics = answer_attrs.delete(:metrics))
        metrics.each { |key, values| answer.assign_metrics(key, values) }
      end

      if (llm_response = answer_attrs.delete(:llm_response))
        llm_response.each { |namespace, values| answer.assign_llm_response(namespace, values) }
      end

      answer.sources.each { |source| source.used = false }
      answer.assign_attributes(answer_attrs)
      answer
    end

    def abort_pipeline!(...)
      abort_pipeline(...)
      throw :abort
    end

    def aborted?
      @aborted
    end

    def question_message=(question_message)
      answer.rephrased_question = question_message != question.message ? question_message : nil
      @question_message = question_message
    end

    def search_results=(search_results)
      answer.build_sources_from_search_results(search_results)
      @search_results = search_results
    end

    def update_sources_from_exact_paths_used(exact_paths)
      used_sources = exact_paths.filter_map do |exact_path|
        answer.sources.find { |source| source.exact_path == exact_path }
      end

      if used_sources.empty?
        answer.sources.each { |source| source.used = true }
        return answer.sources
      end

      used_sources.each_with_index do |source, index|
        source.used = true
        source.relevancy = index
      end

      unused_sources = answer.sources - used_sources

      unused_sources.each.with_index(used_sources.length) do |source, index|
        source.used = false
        source.relevancy = index
      end

      answer.sources = used_sources + unused_sources
    end
  end
end
