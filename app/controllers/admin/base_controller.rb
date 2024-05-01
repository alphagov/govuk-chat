class Admin::BaseController < ApplicationController
  prepend_before_action { authorise_user!(User::Permissions::ADMIN_AREA) }
  layout "admin"
end
