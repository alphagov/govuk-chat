class User < ApplicationRecord
  include GDS::SSO::User

  module Permissions
    DEVELOPER_TOOLS = "developer-tools".freeze
  end

  def flipper_id
    email || id
  end
end
