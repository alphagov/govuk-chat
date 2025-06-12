class SignonUser < ApplicationRecord
  include GDS::SSO::User

  module Permissions
    ADMIN_AREA = "admin-area".freeze
    ADMIN_AREA_SETTINGS = "admin-area-settings".freeze
    CONVERSATION_API = "conversation-api".freeze
    DEVELOPER_TOOLS = "developer-tools".freeze
    WEB_CHAT = "web-chat".freeze
  end

  def has_permission?(permission)
    permissions.include?(permission)
  end

  has_many :conversations
end
