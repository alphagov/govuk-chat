module Evaluation
  class ReportGenerator
    def self.call(...) = new.call(...)

    def self.evaluation_questions
      YAML.load_file(Rails.root.join("lib/data/evaluation/questions.yml"))
    end

    def call
      questions = self.class.evaluation_questions

      questions.map.with_index do |evaluation_question, index|
        yield questions.size, index + 1, evaluation_question if block_given?

        question = build_question(evaluation_question)
        answer = AnswerComposition::Composer.call(question)

        {
          question: evaluation_question,
          llm_answer: answer.message,
          retrieved_context: answer.sources.select(&:used?).flat_map(&method(:build_retrieved_context)),
        }
      end
    end

  private

    def build_question(question_message)
      Question.new(message: question_message, conversation: Conversation.new)
    end

    def absolute_govuk_url(path)
      Plek.website_root + path
    end

    def build_retrieved_context(source)
      begin
        chunk = repository.chunk(source.content_chunk_id)
      rescue Search::ChunkedContentRepository::NotFound
        return { error: "Could not find content chunk" }
      end

      if chunk.digest != source.content_chunk_digest
        return { error: "Content chunk digest mismatch" }
      end

      {
        title: source.title,
        heading_hierarchy: chunk.heading_hierarchy,
        description: chunk.description,
        html_content: chunk.html_content,
        exact_path: absolute_govuk_url(source.exact_path),
        base_path: absolute_govuk_url(source.base_path),
      }
    end

    def repository
      @repository ||= Search::ChunkedContentRepository.new
    end
  end
end
