Passwordless.configure do |config|
  config.combat_brute_force_attacks = true
  config.default_from_address = "something@www.gov.uk"
  config.restrict_token_reuse = true
  config.expires_at = -> { 30.days.from_now } # How long until a signed in session expires.
  config.timeout_at = -> { 24.hours.from_now } # How long until a token/magic link times out.
  config.token_generator = ->(_session) { SecureRandom.hex(32) }
  config.redirect_back_after_sign_in = true
end

Rails.application.config.to_prepare do
  Passwordless::Session.strict_loading_by_default = false
end
