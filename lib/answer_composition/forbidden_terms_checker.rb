module AnswerComposition
  class ForbiddenTermsChecker
    attr_reader :answer, :forbidden_terms

    def self.call(...) = new(...).call

    def initialize(answer)
      @answer = answer
      @forbidden_terms = Rails.configuration.forbidden_terms
    end

    def call
      start_time = Clock.monotonic_time

      if contains_forbidden_term?
        answer.set_sources_as_unused
        answer.assign_attributes(
          status: "guardrails_forbidden_terms",
          message: Answer::CannedResponses::FORBIDDEN_TERMS_MESSAGE,
        )
      end

      answer.assign_metrics("forbidden_terms_checker", build_metrics(start_time))
    end

  private

    def contains_forbidden_term?
      # Regex matches words or phrases that aren't a subtring of a longer word.
      # It will match if the word is preceded or followed by a non-letter character.
      # i.e badword! or !badword or 1badword or badword1
      regex = /(\A|[^a-z])(#{forbidden_terms.map(&Regexp.method(:escape)).join('|')})([^a-z]|\Z)/
      answer.message.downcase.match?(regex)
    end

    def build_metrics(start_time)
      { duration: Clock.monotonic_time - start_time }
    end
  end
end
