class GenerateAnswerFromChatApiJob < ApplicationJob
  queue_as :default

  def perform(question_id)
    question = Question.find_by(id: question_id)
    return logger.warn("No question found for #{question_id}") unless question
    return logger.warn("Question #{question_id} has already been answered") if question.answer

    response = generate_response(question)

    ActiveRecord::Base.transaction do
      answer = question.create_answer!(message: response["answer"])
      response["sources"].each { |url| answer.answer_sources.create!(url:) }
    end
  end

private

  def generate_response(question)
    body = { chat_id: question.conversation_id, user_query: question.message }.to_json
    response = http_client.post("/govchat", body)
    JSON.parse(response.body)
  end

  def http_client
    http_client = Faraday.new(
      url: ENV["CHAT_API_URL"],
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
      },
    )
    http_client.set_basic_auth(ENV["CHAT_API_USERNAME"], ENV["CHAT_API_PASSWORD"])
    http_client
  end
end
