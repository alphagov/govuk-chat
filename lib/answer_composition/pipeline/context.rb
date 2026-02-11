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

      answer.set_sources_as_unused
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

    def update_sources_from_exact_urls_used(exact_urls)
      used_sources = exact_urls.filter_map do |exact_url|
        answer.sources.find { |source| source.govuk_url == exact_url }
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

    def search_results_prompt_formatted(link_token_mapper)
      search_results.map do |result|
        {
          page_url: link_token_mapper.map_link_to_token(result.exact_path),
          page_title: result.title,
          page_description: result.description,
          context_headings: result.heading_hierarchy,
          context_content: link_token_mapper.map_links_to_tokens(
            result.html_content,
            result.exact_path,
          ),
          llm_instructions: result.llm_instructions,
        }.compact
      end
    end
  end
end
