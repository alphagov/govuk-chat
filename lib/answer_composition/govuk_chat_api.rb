module AnswerComposition
  class GovukChatApi
    def self.call(...) = new(...).call

    def initialize(question)
      @question = question
    end

    def call
      answer = question.build_answer(message: response["answer"], status: "success")
      response["sources"].each.with_index do |url, index|
        answer.sources.build(url: return_base_path(url), relevancy: index)
      end
      answer
    end

  private

    attr_reader :question

    def response
      @response ||= begin
        body = { chat_id: "app_#{question.conversation_id}", user_query: question.message }.to_json
        response = http_client.post("/govchat", body)
        JSON.parse(response.body)
      end
    end

    def http_client
      Faraday.new(url: ENV["CHAT_API_URL"]) do |faraday|
        faraday.headers["Content-Type"] = "application/json"
        faraday.headers["Accept"] = "application/json"
        faraday.set_basic_auth(ENV["CHAT_API_USERNAME"], ENV["CHAT_API_PASSWORD"])
      end
    end

    def return_base_path(url)
      URI.parse(url).path
    end
  end
end
