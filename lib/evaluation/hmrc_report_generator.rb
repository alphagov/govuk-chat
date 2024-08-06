module Evaluation
  class HmrcReportGenerator
    HEADERS = ["Question", "Answer", "Sources Returned"].freeze

    def self.call(...) = new.call(...)

    def self.evaluation_questions
      YAML.load_file(Rails.root.join("lib/data/evaluation/hmrc_questions.yml"))
    end

    def call
      questions = self.class.evaluation_questions

      rows = questions.map.with_index do |evaluation_question, index|
        yield questions.size, index + 1, evaluation_question if block_given?

        question = build_question(evaluation_question)
        answer = AnswerComposition::Composer.call(question)

        [
          evaluation_question,
          answer.message,
          answer.sources.map(&method(:build_source)).join("\n"),
        ]
      end

      [HEADERS] + rows
    end

  private

    def build_question(question_message)
      Question.new(message: question_message, conversation: Conversation.new)
    end

    def full_url(path)
      "https://www.gov.uk#{path}"
    end

    def build_source(source)
      full_url(source.exact_path)
    end
  end
end
