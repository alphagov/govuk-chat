class SignonUser < ApplicationRecord
  include GDS::SSO::User

  module Permissions
    ADMIN_AREA = "admin-area".freeze
    DEVELOPER_TOOLS = "developer-tools".freeze
  end
end
