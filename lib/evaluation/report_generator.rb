module Evaluation
  class ReportGenerator
    def self.call(...) = new.call(...)

    def call(input_path)
      raise "File #{input_path} does not exist" unless File.exist?(input_path)

      questions = YAML.load_file(input_path)
      answer_strategy = Rails.configuration.answer_strategy

      questions.map.with_index do |evaluation_question, index|
        yield questions.size, index + 1, evaluation_question if block_given?

        question = build_question(evaluation_question)
        answer = AnswerComposition::Composer.call(question)

        # without DB persistence data as it isn't saved to the DB
        answer_json = answer.as_json(except: %i[id question_id created_at updated_at])

        {
          question: evaluation_question,
          answer: answer_json,
          answer_strategy:,
          retrieved_context: answer.sources.map(&method(:build_retrieved_context)),
        }
      end
    end

  private

    def build_question(question_message)
      Question.new(
        message: question_message,
        conversation: Conversation.new,
        answer_strategy: Rails.configuration.answer_strategy,
      )
    end

    def build_retrieved_context(source)
      {
        search_score: source.search_score,
        weighted_score: source.weighted_score,
        used: source.used,
        chunk: source.chunk.as_json(except: %i[id updated_at created_at]).symbolize_keys,
      }
    end
  end
end
