class AdminUser < ApplicationRecord
  include GDS::SSO::User

  module Permissions
    ADMIN_AREA = "admin-area".freeze
    API_USER = "api-user".freeze
    DEVELOPER_TOOLS = "developer-tools".freeze
  end
end
