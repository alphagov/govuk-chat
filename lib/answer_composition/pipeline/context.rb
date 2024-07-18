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
  end
end
