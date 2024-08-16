class Admin::Filters::PilotUsers::WaitingListUsersFilter < Admin::Filters::PilotUsers::BaseFilter
  DEFAULT_SORT = "-created_at".freeze
  VALID_SORT_VALUES = ["created_at", "-created_at", "email", "-email"].freeze

  attribute :email

  def initialize(...)
    super
    self.sort = DEFAULT_SORT unless VALID_SORT_VALUES.include?(sort)
  end

  def users
    @users ||= begin
      scope = WaitingListUser
      scope = email_scope(scope)
      scope = ordering_scope(scope)
      scope.page(page).per(25)
    end
  end

private

  def pagination_query_params
    filters = {}
    filters[:email] = email if email.present?
    filters[:sort] = sort if sort != DEFAULT_SORT

    filters
  end

  def ordering_scope(scope)
    column = sort.delete_prefix("-")
    direction = sort.start_with?("-") ? :desc : :asc
    scope.order("#{column}": direction)
  end
end
