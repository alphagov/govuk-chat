class SignonUser < ApplicationRecord
  include GDS::SSO::User

  module Permissions
    ADMIN_AREA = "admin-area".freeze
    CONVERSATION_API = "conversation-api".freeze
    DEVELOPER_TOOLS = "developer-tools".freeze
  end

  has_many :conversations
end
