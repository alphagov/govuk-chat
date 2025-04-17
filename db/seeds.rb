SignonUser.find_or_create_by!(name: "chat_user", email: "chat.user@dev.gov.uk").update!(uid: SecureRandom.uuid, permissions: %w[developer-tools admin-area])
