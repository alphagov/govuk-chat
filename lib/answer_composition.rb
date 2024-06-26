module AnswerComposition
  FORBIDDEN_WORDS_RESPONSE = "<p>Sorry, I cannot answer that. Ask me a question about " \
    "business or trade and I'll use GOV.UK guidance to answer it.</p>".freeze
  NO_CONTENT_FOUND_REPONSE = "<p>Sorry, I can't find anything on GOV.UK to help me answer your question. " \
    "Could you rewrite it so I can try answering again?</p>".freeze
  CONTEXT_LENGTH_EXCEEDED_RESPONSE = "<p>Sorry, I can't answer that in one go. Could you make your question " \
    "simpler or more specific, or ask each part separately?</p>".freeze
  OPENAI_CLIENT_ERROR_RESPONSE = <<~MESSAGE.freeze
    <p>Sorry, there is a problem with OpenAI's API. Try again later.</p>
    <p>We saved your conversation.</p>
    <p>Check <a href="https://www.gov.uk/browse/business">GOV.UK guidance for businesses</a> if you need information now.</p>
  MESSAGE
  TIMED_OUT_RESPONSE = "<p>Sorry, something went wrong and I could not find an answer in time. " \
    "Please try again.</p>".freeze
end
