module WebMockNotAllowedMessage
  def message
    return super unless ENV["CI"]

    "An unregistered HTTP request was made which WebMock raised an exception for.\n\n" \
    "The details of this exception have been suppressed in CI to prevent" \
    "public disclosure. Replicate this exception locally for further details."
  end
end

# Monkey patch this error as a means to prevent outputting full HTTP request
# details in the CI environment. The motivation for this is to reduce the risk
# that this could make a private prompt public.
WebMock::NetConnectNotAllowedError.prepend(WebMockNotAllowedMessage)
