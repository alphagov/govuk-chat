class Admin::BaseController < ApplicationController
  prepend_before_action { authorise_user!(AdminUser::Permissions::ADMIN_AREA) }
  layout "admin"
end
