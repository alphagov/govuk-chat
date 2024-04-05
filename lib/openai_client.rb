class OpenAIClient
  # Create error classes we expect we may have to handle, these need
  # to be generated from faraday ones: https://github.com/lostisland/faraday/blob/main/lib/faraday/error.rb
  class RequestError < Faraday::Error; end
  class ClientError < RequestError; end
  class ServerError < RequestError; end

  class ErrorMiddleware < Faraday::Middleware
    def call(env)
      @app.call(env)
    rescue Faraday::ClientError => e
      raise ClientError.new(e, e.response)
    rescue Faraday::ServerError => e
      raise ServerError.new(e, e.response)
    rescue Faraday::Error => e
      raise RequestError.new(e, e.response)
    end
  end

  def self.build
    OpenAI::Client.new(access_token: ENV.fetch("OPENAI_ACCESS_TOKEN")) do |faraday|
      # We don't want to use this middleware because it adds extra logging to stdout
      # It should be removed by default from OpenAI Ruby when https://github.com/alexrudall/ruby-openai/pull/406
      # is released
      faraday.builder.delete(OpenAI::MiddlewareErrors)

      # Use our own middleware to wrap OpenAI errors in distinct exceptions from Faraday ones
      faraday.builder.insert_before(Faraday::Response::RaiseError, ErrorMiddleware)
    end
  end
end
