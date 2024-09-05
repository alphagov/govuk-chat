class Admin::BaseController < ApplicationController
  layout "admin"
  before_action { authorise_user!(AdminUser::Permissions::ADMIN_AREA) }
  before_action { Current.admin_user = current_user }
end
