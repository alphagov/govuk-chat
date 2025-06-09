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
          retrieved_context: answer.sources.flat_map(&method(:build_retrieved_context)),
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
      data = {
        title: source.title,
        used: source.used,
        exact_path: source.exact_path,
        base_path: source.base_path,
        content_chunk_id: source.content_chunk_id,
        content_chunk_available: false,
      }

      begin
        chunk = repository.chunk(source.content_chunk_id)
      rescue Search::ChunkedContentRepository::NotFound
        return data
      end

      if chunk.digest != source.content_chunk_digest
        return data
      end

      data.merge({
        content_chunk_available: true,
        heading_hierarchy: chunk.heading_hierarchy,
        description: chunk.description,
        html_content: chunk.html_content,
      })
    end

    def repository
      @repository ||= Search::ChunkedContentRepository.new
    end
  end
end
