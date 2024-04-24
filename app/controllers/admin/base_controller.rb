class Admin::BaseController < ApplicationController
  before_action { authorise_user!(User::Permissions::ADMIN_AREA) }
  layout "admin"
end
