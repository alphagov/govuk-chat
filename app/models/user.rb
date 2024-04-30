class User < ApplicationRecord
  include GDS::SSO::User

  module Permissions
    DEVELOPER_TOOLS = "developer-tools".freeze
  end
end
