class Search::TextToEmbedding
  class TitanAsync
    MAX_CONCURRENCY = 5

    def self.call(...) = new(...).call

    def initialize(single_or_collection_of_text)
      @string_input = single_or_collection_of_text.is_a?(String)
      @text_collection = Array(single_or_collection_of_text)
    end

    def call
      embeddings = convert_text_to_embeddings(text_collection)

      # return just first embedding rather than an array of embeddings if we
      # weren't given an array input
      string_input ? embeddings.first : embeddings
    end

  private

    attr_reader :string_input, :text_collection

    def credentials
      Aws::CredentialProviderChain.new.resolve
    end

    def signer
      Aws::Sigv4::Signer.new(service: "bedrock", region: "eu-west-1", credentials:)
    end

    def body(text)
      JSON.generate(inputText: text)
    end

    def url
      "https://bedrock-runtime.eu-west-1.amazonaws.com/model/#{BedrockModels.model_id(:titan_embed_v2)}/invoke"
    end

    def headers(text)
      uri = URI.parse(url)
      base_headers = {
        "host" => uri.host,
        "content-type" => "application/json",
        "accept" => "application/json",
      }

      signed_headers = signer.sign_request(
        http_method: "POST",
        url:,
        headers: base_headers,
        body: body(text),
      ).headers

      base_headers.merge(signed_headers)
    end

    def convert_text_to_embeddings(text_collection)
      return [] if text_collection.empty?

      hydra = Typhoeus::Hydra.new(max_concurrency: MAX_CONCURRENCY)
      results = Array.new(text_collection.length)
      errors = []

      text_collection.each_with_index do |text, index|
        request = Typhoeus::Request.new(
          url,
          method: :post,
          headers: headers(text),
          body: body(text),
        )

        request.on_complete do |response|
          if response.success?
            results[index] = JSON.parse(response.body).fetch("embedding")
          else
            errors << "Bedrock request failed (code=#{response.code})"
          end
        rescue StandardError => e
          errors << e
        end

        hydra.queue(request)
      end

      hydra.run

      raise errors.first if errors.any?

      results
    end
  end
end
