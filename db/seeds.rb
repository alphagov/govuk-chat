User.find_or_create_by!(uid: SecureRandom.uuid, name: "chat_user", email: "chat.user@dev.gov.uk", permissions: %w[developer-tools])
